-- CLEAN DELETE ADMIN SCRIPT
-- Purpose: Remove mrma007fb@gmail.com from ALL tables so you can Sign Up again cleanly.

-- 1. Delete from admin_directory (if exists)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'admin_directory') THEN
        DELETE FROM public.admin_directory 
        WHERE id IN (SELECT id FROM auth.users WHERE email = 'mrma007fb@gmail.com');
    END IF;
END $$;

-- 2. Delete from public.users
DELETE FROM public.users 
WHERE email = 'mrma007fb@gmail.com';

-- 3. Delete from auth.users
DELETE FROM auth.users 
WHERE email = 'mrma007fb@gmail.com';

SELECT 'User Deleted. You can now Sign Up in the App.' as status;
