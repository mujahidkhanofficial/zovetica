-- DATA REPAIR SCRIPT
-- Purpose: Force-fix the internal Auth fields for the admin user.
-- This fixes "500 Database Error" caused by missing/corrupt instance_id or metadata.

-- 1. Update auth.users with correct system values
UPDATE auth.users
SET 
  instance_id = '00000000-0000-0000-0000-000000000000', -- Critical: Must be all zeros
  aud = 'authenticated',
  role = 'authenticated',
  email_confirmed_at = COALESCE(email_confirmed_at, now()),
  raw_user_meta_data = jsonb_build_object(
    'role', 'admin',
    'full_name', 'Admin User',
    'iss', 'https://api.supabase.io'
  ),
  raw_app_meta_data = jsonb_build_object(
    'provider', 'email',
    'providers', ARRAY['email']
  )
WHERE email = 'mrma007fb@gmail.com';

-- 2. Ensure public.users matches
UPDATE public.users
SET role = 'admin'
WHERE email = 'mrma007fb@gmail.com';

-- 3. Ensure they are in the admin directory (Access Check fix)
INSERT INTO public.admin_directory (id)
SELECT id FROM auth.users WHERE email = 'mrma007fb@gmail.com'
ON CONFLICT (id) DO NOTHING;

-- 4. Reload Schema (Just in case)
NOTIFY pgrst, 'reload schema';

SELECT 'User Repaired. Try logging in.' as status;
