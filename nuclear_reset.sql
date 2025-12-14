-- NUCLEAR RESET SCRIPT
-- Purpose: The "scorched earth" approach. Deletes ALL custom admin logic, triggers, and policies.
-- Use this when nothing else works to fix "Database error querying schema".

-- 1. Drop the potential problem tables/functions cascade
DROP TABLE IF EXISTS public.admin_directory CASCADE;
DROP FUNCTION IF EXISTS public.is_admin() CASCADE;
DROP FUNCTION IF EXISTS public.sync_admin_directory() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- 2. Drop ALL Triggers on auth.users (Clean slate)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;

-- 3. Drop ALL Triggers on public.users
DROP TRIGGER IF EXISTS on_user_role_change ON public.users;

-- 4. Strip Security from Main Tables
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctors DISABLE ROW LEVEL SECURITY;

-- 5. Drop ALL Policies on public.users (Just to be sure)
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Admins can update users" ON public.users;
DROP POLICY IF EXISTS "Everyone can view users" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;

-- 6. Repair Permissions (In case PostgREST lost access)
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- 7. Reload Schema
NOTIFY pgrst, 'reload schema';

SELECT 'NUCLEAR RESET COMPLETE. Try Logging In.' as status;
