-- RESET SUPER ADMIN SCRIPT
-- Purpose: Delete potential corrupt user and create a fresh Super Admin.
-- Email: mrma007fb@gmail.com
-- Password: zovetica@786

-- 1. Clean up existing references (Order matters for Foreign Keys)
DELETE FROM public.admin_directory 
WHERE id IN (SELECT id FROM auth.users WHERE email = 'mrma007fb@gmail.com');

DELETE FROM public.users 
WHERE email = 'mrma007fb@gmail.com';

DELETE FROM auth.users 
WHERE email = 'mrma007fb@gmail.com';

-- 2. Create the Auth User
-- We use a variable for ID to ensure we use the same one for all tables
DO $$
DECLARE
  new_user_id uuid := gen_random_uuid();
BEGIN
  -- Insert into auth.users
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    new_user_id,
    'authenticated',
    'authenticated',
    'mrma007fb@gmail.com',
    crypt('zovetica@786', gen_salt('bf')), -- PASSWORD: zovetica@786
    now(),
    '{"provider": "email", "providers": ["email"]}',
    '{"role": "super_admin", "full_name": "Super Admin"}',
    now(),
    now()
  );

  -- Insert into public.users
  INSERT INTO public.users (
    id,
    email,
    name,
    role,
    created_at
  ) VALUES (
    new_user_id,
    'mrma007fb@gmail.com',
    'Super Admin',
    'super_admin',
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    role = 'super_admin',
    name = 'Super Admin';

  -- Insert into admin_directory (For our RLS Fix)
  INSERT INTO public.admin_directory (id)
  VALUES (new_user_id)
  ON CONFLICT (id) DO NOTHING;

END $$;

SELECT 'Super Admin Reset Complete. Password is: zovetica@786' as status;
