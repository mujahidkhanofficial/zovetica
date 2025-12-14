-- PROMOTE TO SUPER ADMIN
-- Purpose: Run this AFTER you have signed up in the app.

-- 1. Update public.users
UPDATE public.users
SET role = 'super_admin', name = 'Super Admin'
WHERE email = 'mrma007fb@gmail.com';

-- 2. Update auth.metadata (optional but good for consistency)
UPDATE auth.users
SET raw_user_meta_data = jsonb_build_object('role', 'super_admin')
WHERE email = 'mrma007fb@gmail.com';

-- 3. Add to admin_directory (Future proofing)
-- Ensure table exists (in case of nuclear reset)
CREATE TABLE IF NOT EXISTS public.admin_directory (
    id uuid REFERENCES auth.users NOT NULL PRIMARY KEY,
    created_at timestamptz DEFAULT now()
);

INSERT INTO public.admin_directory (id)
SELECT id FROM auth.users WHERE email = 'mrma007fb@gmail.com'
ON CONFLICT (id) DO NOTHING;

SELECT 'User Promoted to Super Admin.' as status;
