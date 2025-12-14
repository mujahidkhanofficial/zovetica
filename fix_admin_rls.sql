-- Zovetica Admin Panel - FIXED RLS Policies
-- This fixes the infinite recursion issue in admin_migration.sql
-- Run this in your Supabase SQL Editor

-- Step 1: Drop the problematic policies
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Admins can update users" ON public.users;
DROP POLICY IF EXISTS "Admins can delete any post" ON public.posts;
DROP POLICY IF EXISTS "Admins can update any post" ON public.posts;
DROP POLICY IF EXISTS "Admins can manage doctors" ON public.doctors;
DROP POLICY IF EXISTS "Admins can view all appointments" ON public.appointments;
DROP POLICY IF EXISTS "Admins can update appointments" ON public.appointments;

-- Step 2: Create a SECURITY DEFINER function to check admin status
-- This bypasses RLS and prevents the recursion
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND role IN ('admin', 'super_admin')
  );
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;

-- Step 3: Add columns if they don't exist (safe to re-run)
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS banned_at timestamptz;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS banned_reason text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS banned_by uuid;

ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS is_flagged boolean DEFAULT false;
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS flagged_at timestamptz;
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS flagged_reason text;
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS moderated_by uuid;

ALTER TABLE public.doctors ADD COLUMN IF NOT EXISTS rejection_reason text;
ALTER TABLE public.doctors ADD COLUMN IF NOT EXISTS verified_at timestamptz;
ALTER TABLE public.doctors ADD COLUMN IF NOT EXISTS verified_by uuid;

-- Step 4: Create FIXED RLS policies using the is_admin() function

-- Users table policies (FIXED)
CREATE POLICY "Users can view own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Admins can view all users"
  ON public.users FOR SELECT
  USING (is_admin());

CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admins can update users"
  ON public.users FOR UPDATE
  USING (is_admin());

-- Posts table policies (FIXED)
CREATE POLICY "Admins can delete any post"
  ON public.posts FOR DELETE
  USING (user_id = auth.uid() OR is_admin());

CREATE POLICY "Admins can update any post"
  ON public.posts FOR UPDATE
  USING (user_id = auth.uid() OR is_admin());

-- Doctors table policies (FIXED)
CREATE POLICY "Admins can manage doctors"
  ON public.doctors FOR ALL
  USING (user_id = auth.uid() OR is_admin());

-- Appointments table policies (FIXED)
CREATE POLICY "Admins can view all appointments"
  ON public.appointments FOR SELECT
  USING (
    user_id = auth.uid() OR
    doctor_id IN (SELECT id FROM public.doctors WHERE user_id = auth.uid()) OR
    is_admin()
  );

CREATE POLICY "Admins can update appointments"
  ON public.appointments FOR UPDATE
  USING (
    user_id = auth.uid() OR
    doctor_id IN (SELECT id FROM public.doctors WHERE user_id = auth.uid()) OR
    is_admin()
  );

-- Step 5: Recreate the admin stats function
CREATE OR REPLACE FUNCTION get_admin_stats()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result json;
BEGIN
  -- Only allow admins to call this
  IF NOT is_admin() THEN
    RETURN '{}'::json;
  END IF;

  SELECT json_build_object(
    'total_users', (SELECT COUNT(*) FROM users),
    'total_doctors', (SELECT COUNT(*) FROM doctors),
    'verified_doctors', (SELECT COUNT(*) FROM doctors WHERE verified = true),
    'pending_doctors', (SELECT COUNT(*) FROM doctors WHERE verified = false),
    'total_pets', (SELECT COUNT(*) FROM pets),
    'total_appointments', (SELECT COUNT(*) FROM appointments),
    'pending_appointments', (SELECT COUNT(*) FROM appointments WHERE status = 'pending'),
    'total_posts', (SELECT COUNT(*) FROM posts),
    'flagged_posts', (SELECT COUNT(*) FROM posts WHERE is_flagged = true),
    'banned_users', (SELECT COUNT(*) FROM users WHERE banned_at IS NOT NULL)
  ) INTO result;
  
  RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_admin_stats() TO authenticated;

-- Done!
SELECT 'RLS policies fixed! Login should work now.' as status;
