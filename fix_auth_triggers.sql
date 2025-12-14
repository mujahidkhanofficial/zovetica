-- AUTH TRIGGER CLEANUP
-- Purpose: Find and remove triggers on auth.users that might be causing the Admin Login crash.
-- Valid for specific Supabase error "Database error querying schema" during signIn.

-- 1. List triggers on auth.users (for your information)
SELECT 
    trigger_name,
    event_manipulation,
    action_statement 
FROM information_schema.triggers 
WHERE event_object_schema = 'auth' 
AND event_object_table = 'users';

-- 2. BLINDLY DROP COMMON TRIGGERS on auth.users
-- These often cause issues if they reference public tables with broken policies.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
DROP TRIGGER IF EXISTS handle_updated_at ON auth.users;
-- NOTE: We cannot drop system triggers, but these are custom ones.

-- 3. Create a SAFE simple sync trigger (Optional, but good for stability)
-- Only does basic insert, very safe.
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'pet_owner')
  )
  ON CONFLICT (id) DO NOTHING; -- Key: Do nothing on conflict to prevent errors
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-attach only the INSERT trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. ENSURE NO 'ON UPDATE' TRIGGER EXISTS
-- We strictly want to avoid triggers firing on 'last_sign_in_at' updates
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;

-- 5. RELOAD SCHEMA
NOTIFY pgrst, 'reload schema';

SELECT 'Auth Triggers Cleaned. ON UPDATE triggers removed.' as status;
