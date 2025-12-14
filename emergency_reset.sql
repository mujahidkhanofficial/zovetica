-- EMERGENCY RESET SCRIPT
-- Purpose: Remove all potential blockers (RLS, Triggers) to verify basic access.
-- Run this in Supabase SQL Editor.

-- 1. Disable RLS temporarily on all affected tables
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_directory DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctors DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments DISABLE ROW LEVEL SECURITY;

-- 2. Drop the custom triggers we created
DROP TRIGGER IF EXISTS on_user_role_change ON public.users;
DROP FUNCTION IF EXISTS public.sync_admin_directory();

-- 3. Drop the policies that might be recursive
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Admins can update users" ON public.users;
DROP POLICY IF EXISTS "Admins can view directory" ON public.admin_directory;

-- 4. Simplified is_admin check (Just returns false/true, no DB query)
-- This ensures no recursion can happen in other policies if they still exist.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SECURITY DEFINER
AS $$
  SELECT true; -- TEMPORARY: Allow everyone to pass is_admin check for debugging
$$;

-- 5. Reload Schema cache
NOTIFY pgrst, 'reload schema';

SELECT 'Emergency Reset Complete. RLS is OFF. Triggers are OFF.' as status;
