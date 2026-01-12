-- ============================================================================
-- BOOTSTRAP SUPER ADMIN - Create your first Super Admin
-- ============================================================================
-- 
-- Since new users are created as 'pet_owner' by default, and you don't have
-- a super_admin yet to promote others, you must run this script MANUALLY
-- in the Supabase SQL Editor to elevate your first user.
--
-- ⚠️ INSTRUCTIONS:
-- 1. Replace 'YOUR_EMAIL_HERE' with the email address of the account you want to promote.
-- 2. Run this script in the Supabase SQL Editor.
-- ============================================================================

DO $$
DECLARE
  v_target_email text := 'YOUR_EMAIL_HERE'; -- 👈 PUT YOUR EMAIL HERE
  v_user_id uuid;
BEGIN
  -- 1. Find user by email
  SELECT id INTO v_user_id FROM auth.users WHERE email = v_target_email;
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User with email % not found. Please sign up first.', v_target_email;
  END IF;

  -- 2. Update public profile role
  UPDATE public.users 
  SET role = 'super_admin'
  WHERE id = v_user_id;
  
  -- 3. Ensure they are in admin_directory (trigger should handle this, but being safe)
  INSERT INTO public.admin_directory (id)
  VALUES (v_user_id)
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE '✅ SUCCESS: User % (%) has been promoted to SUPER ADMIN', v_target_email, v_user_id;
END;
$$;
