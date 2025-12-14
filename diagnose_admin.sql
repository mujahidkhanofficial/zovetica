-- DIAGNOSE ADMIN USER
-- Purpose: Check if the admin user has corrupt data in auth.users or public.users
-- Replace 'admin@zovetica.com' if the user is using a different email.

SELECT 
  id, 
  email, 
  role, 
  created_at, 
  last_sign_in_at,
  raw_user_meta_data,
  raw_app_meta_data,
  instance_id
FROM auth.users
WHERE email = 'mrma007fb@gmail.com';

-- Check public.users counterpart
SELECT 
  id, 
  email, 
  role, 
  created_at
FROM public.users
WHERE email = 'mrma007fb@gmail.com';

-- Check admin_directory
SELECT * FROM public.admin_directory;
