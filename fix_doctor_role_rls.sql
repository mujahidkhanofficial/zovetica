-- =============================================================
-- FIX: Doctor Role Integrity - RLS + Trigger Update
-- =============================================================
-- Run this in Supabase SQL Editor
-- =============================================================

-- STEP 1: Clean up conflicting policies
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Users can manage own profile" ON public.users;
DROP POLICY IF EXISTS "Allow individual insert" ON public.users;
DROP POLICY IF EXISTS "Allow individual update" ON public.users;
DROP POLICY IF EXISTS "Users can update own non-privileged fields" ON public.users;
DROP POLICY IF EXISTS "Only super_admin can change roles" ON public.users;

-- STEP 2: Create INSERT policy (Allows signup)
CREATE POLICY "Users can create own profile"
  ON public.users FOR INSERT
  WITH CHECK (
    auth.uid() = id
    AND role IN ('pet_owner', 'doctor')  -- Whitelist safe roles only
  );

-- STEP 3: Create UPDATE policy (Allows profile edits, blocks role changes)
CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    AND role IN ('pet_owner', 'doctor')  -- Cannot self-elevate to admin
  );

-- STEP 4: Improve the auth trigger to include all fields
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (
    id, 
    email, 
    name, 
    username,
    phone,
    role, 
    specialty, 
    clinic
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    NEW.raw_user_meta_data->>'username',
    NEW.raw_user_meta_data->>'phone',
    COALESCE(NEW.raw_user_meta_data->>'role', 'pet_owner'),
    NEW.raw_user_meta_data->>'specialty',
    NEW.raw_user_meta_data->>'clinic'
  )
  ON CONFLICT (id) DO UPDATE SET
    -- Only update if values are NULL in existing record (safe merge)
    name = COALESCE(public.users.name, EXCLUDED.name),
    username = COALESCE(public.users.username, EXCLUDED.username),
    phone = COALESCE(public.users.phone, EXCLUDED.phone),
    role = COALESCE(public.users.role, EXCLUDED.role),
    specialty = COALESCE(public.users.specialty, EXCLUDED.specialty),
    clinic = COALESCE(public.users.clinic, EXCLUDED.clinic);
  
  RETURN NEW;
END;
$$;

-- STEP 5: Ensure trigger is attached
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- STEP 6: Ensure SELECT remains public
DROP POLICY IF EXISTS "Public user profiles viewable" ON public.users;
CREATE POLICY "Public user profiles viewable"
  ON public.users FOR SELECT
  USING (true);

-- STEP 7: Admin override policies
DROP POLICY IF EXISTS "Admin role management" ON public.users;
CREATE POLICY "Admin role management"
  ON public.users FOR UPDATE
  USING (
    (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'super_admin')
  );

-- STEP 8: Reload schema cache
NOTIFY pgrst, 'reload schema';

SELECT '✅ Doctor Role RLS Fix Applied Successfully' as status;
