-- ============================================================================
-- SAFE PROFILE CREATION TRIGGER - FIX FOR "Database error saving new user"
-- ============================================================================
-- 
-- The error "Database error saving new user" happens when a trigger on 
-- auth.users fails during INSERT. This script creates a SAFE trigger that:
-- 1. Only inserts required columns
-- 2. Uses exception handling to prevent failures
-- 3. Logs errors without blocking user creation
--
-- ⚠️ RUN THIS IN SUPABASE SQL EDITOR
-- ============================================================================

-- First, drop the existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create a SAFE trigger function with error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _full_name text;
  _username text;
  _phone text;
BEGIN
  -- Extract metadata safely with defaults
  _full_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    'User'
  );
  _username := NEW.raw_user_meta_data->>'username';
  _phone := NEW.raw_user_meta_data->>'phone';

  -- Insert into public.users with ONLY required columns
  -- Uses ON CONFLICT to handle race conditions/duplicates
  BEGIN
    INSERT INTO public.users (
      id,
      email,
      name,
      role
    )
    VALUES (
      NEW.id,
      NEW.email,
      _full_name,
      'pet_owner'  -- ALWAYS pet_owner - prevents privilege escalation
    )
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      name = COALESCE(EXCLUDED.name, public.users.name);
      
    -- Update optional fields separately (they might not exist in schema)
    BEGIN
      UPDATE public.users SET
        username = COALESCE(_username, username),
        phone = COALESCE(_phone, phone)
      WHERE id = NEW.id;
    EXCEPTION WHEN OTHERS THEN
      -- Column might not exist - ignore
      RAISE NOTICE 'Optional columns update skipped: %', SQLERRM;
    END;
    
  EXCEPTION WHEN OTHERS THEN
    -- Log the error but DON'T block user creation
    RAISE NOTICE 'Profile creation failed (will be created on first login): %', SQLERRM;
  END;
  
  -- ALWAYS return NEW to allow the auth.users insert to succeed
  RETURN NEW;
END;
$$;

-- Create the trigger with AFTER INSERT (safer than BEFORE)
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO service_role;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO postgres;

-- Verify the trigger exists
SELECT tgname, tgtype, tgenabled 
FROM pg_trigger 
WHERE tgname = 'on_auth_user_created';

SELECT '✅ SAFE TRIGGER INSTALLED - Signup should now work' as status;
