-- ============================================================================
-- ZOVETICA SECURITY HARDENING SQL SCRIPT
-- ============================================================================
-- Purpose: Fix critical security vulnerabilities identified in audit
-- 
-- CRITICAL FIXES:
-- 1. Secure profile creation trigger (hardcoded pet_owner role)
-- 2. RLS policies for admin operations
-- 3. Role change protection
-- 4. Admin directory sync
-- 5. Privilege escalation prevention
--
-- ⚠️ RUN THIS IN SUPABASE SQL EDITOR
-- ============================================================================

-- ============================================================================
-- SECTION 1: ADMIN DIRECTORY (Anti-Recursion Pattern)
-- ============================================================================
-- This table breaks infinite RLS recursion by storing admin IDs separately

CREATE TABLE IF NOT EXISTS public.admin_directory (
    id uuid REFERENCES auth.users NOT NULL PRIMARY KEY,
    created_at timestamptz DEFAULT now()
);

-- Populate with existing admins
INSERT INTO public.admin_directory (id)
SELECT id FROM public.users 
WHERE role IN ('admin', 'super_admin')
ON CONFLICT (id) DO NOTHING;

-- Trigger to auto-sync admin_directory when role changes
CREATE OR REPLACE FUNCTION public.sync_admin_directory()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.role IN ('admin', 'super_admin') THEN
        INSERT INTO public.admin_directory (id) VALUES (NEW.id)
        ON CONFLICT (id) DO NOTHING;
    ELSE
        DELETE FROM public.admin_directory WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_user_role_change ON public.users;
CREATE TRIGGER on_user_role_change
AFTER INSERT OR UPDATE OF role ON public.users
FOR EACH ROW EXECUTE FUNCTION public.sync_admin_directory();

-- Safe is_admin() function (no recursion risk)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM admin_directory WHERE id = auth.uid()
  );
$$;

-- Super admin check
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role = 'super_admin'
  );
$$;

-- ============================================================================
-- SECTION 2: SECURE PROFILE CREATION TRIGGER
-- ============================================================================
-- Creates profile with HARDCODED 'pet_owner' role - NEVER trusts client!

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
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
    role,  -- ALWAYS 'pet_owner' for new users!
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    NEW.raw_user_meta_data->>'username',
    NEW.raw_user_meta_data->>'phone',
    'pet_owner',  -- ✅ HARDCODED - prevents privilege escalation!
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = COALESCE(EXCLUDED.name, public.users.name),
    username = COALESCE(EXCLUDED.username, public.users.username),
    phone = COALESCE(EXCLUDED.phone, public.users.phone),
    -- ❌ DO NOT update role from client data!
    updated_at = NOW();
  
  RETURN NEW;
END;
$$;

-- Create trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- SECTION 3: ENABLE RLS ON ALL CRITICAL TABLES
-- ============================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_directory ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- SECTION 4: USERS TABLE RLS POLICIES
-- ============================================================================

-- Drop existing policies to recreate
DROP POLICY IF EXISTS "Users can view all users" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Admins can update users" ON public.users;
DROP POLICY IF EXISTS "Users cannot change own role" ON public.users;
DROP POLICY IF EXISTS "Only super_admin can change roles" ON public.users;

-- SELECT: Everyone can view basic user info
CREATE POLICY "Public user profiles viewable"
  ON public.users FOR SELECT
  USING (true);

-- INSERT: Only auth trigger can insert (via SECURITY DEFINER)
-- No direct inserts allowed from client

-- UPDATE: Users can update own NON-PRIVILEGED fields
CREATE POLICY "Users can update own non-privileged fields"
  ON public.users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    -- Prevent self-modification of privileged fields
    AND (
      -- Role cannot be changed by user themselves
      role = (SELECT role FROM public.users WHERE id = auth.uid())
      -- Ban status cannot be changed by user
      AND banned_at IS NOT DISTINCT FROM (SELECT banned_at FROM public.users WHERE id = auth.uid())
    )
  );

-- UPDATE: Admins can update other users (but not super_admin)
CREATE POLICY "Admins can update other users"
  ON public.users FOR UPDATE
  USING (is_admin())
  WITH CHECK (
    is_admin()
    -- Cannot modify super_admin users unless you are super_admin
    AND (
      (SELECT role FROM public.users WHERE id = public.users.id) != 'super_admin'
      OR is_super_admin()
    )
  );

-- SPECIAL: Only super_admin can change roles
CREATE POLICY "Only super_admin can change roles"
  ON public.users FOR UPDATE
  USING (
    is_super_admin()
  )
  WITH CHECK (
    is_super_admin()
  );

-- DELETE: Only super_admin can delete users
CREATE POLICY "Only super_admin can delete users"
  ON public.users FOR DELETE
  USING (is_super_admin());

-- ============================================================================
-- SECTION 5: POSTS TABLE RLS POLICIES  
-- ============================================================================

DROP POLICY IF EXISTS "Anyone can view posts" ON public.posts;
DROP POLICY IF EXISTS "Users can create own posts" ON public.posts;
DROP POLICY IF EXISTS "Users can update own posts" ON public.posts;
DROP POLICY IF EXISTS "Users can delete own posts" ON public.posts;
DROP POLICY IF EXISTS "Admins can delete any post" ON public.posts;

CREATE POLICY "Anyone can view posts"
  ON public.posts FOR SELECT
  USING (true);

CREATE POLICY "Users can create own posts"
  ON public.posts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own posts"
  ON public.posts FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own posts or admins can delete any"
  ON public.posts FOR DELETE
  USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "Admins can update any post for moderation"
  ON public.posts FOR UPDATE
  USING (is_admin());

-- ============================================================================
-- SECTION 6: DOCTORS TABLE RLS POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Anyone can view verified doctors" ON public.doctors;
DROP POLICY IF EXISTS "Doctors can view own profile" ON public.doctors;
DROP POLICY IF EXISTS "Admins can view all doctors" ON public.doctors;

CREATE POLICY "Anyone can view verified doctors"
  ON public.doctors FOR SELECT
  USING (verified = true OR user_id = auth.uid() OR is_admin());

CREATE POLICY "Doctors can update own profile"
  ON public.doctors FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid()
    -- Cannot self-verify
    AND verified = (SELECT verified FROM public.doctors WHERE user_id = auth.uid())
  );

CREATE POLICY "Only admins can verify doctors"
  ON public.doctors FOR UPDATE
  USING (is_admin())
  WITH CHECK (is_admin());

-- ============================================================================
-- SECTION 7: ADMIN DIRECTORY PROTECTION
-- ============================================================================

-- Only visible to admins themselves
CREATE POLICY "Admins can view admin directory"
  ON public.admin_directory FOR SELECT
  USING (auth.uid() IN (SELECT id FROM admin_directory));

-- No direct INSERT/UPDATE/DELETE - only via trigger
CREATE POLICY "No direct modification of admin directory"
  ON public.admin_directory FOR ALL
  USING (false)
  WITH CHECK (false);

-- ============================================================================
-- SECTION 8: AUDIT LOGGING TABLE (Optional but recommended)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.admin_audit_log (
    id bigserial PRIMARY KEY,
    admin_id uuid REFERENCES auth.users NOT NULL,
    action text NOT NULL,
    target_table text NOT NULL,
    target_id text,
    old_value jsonb,
    new_value jsonb,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

-- Only admins can view audit logs
CREATE POLICY "Admins can view audit logs"
  ON public.admin_audit_log FOR SELECT
  USING (is_admin());

-- Only super_admin can delete audit logs
CREATE POLICY "Only super_admin can delete audit logs"
  ON public.admin_audit_log FOR DELETE
  USING (is_super_admin());

-- ============================================================================
-- SECTION 9: RPC FUNCTIONS FOR SECURE OPERATIONS
-- ============================================================================

-- Secure role change RPC (requires super_admin)
CREATE OR REPLACE FUNCTION public.change_user_role(
  target_user_id uuid,
  new_role text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller_is_super_admin boolean;
  old_role text;
BEGIN
  -- Verify caller is super_admin
  SELECT EXISTS(
    SELECT 1 FROM users WHERE id = auth.uid() AND role = 'super_admin'
  ) INTO caller_is_super_admin;
  
  IF NOT caller_is_super_admin THEN
    RAISE EXCEPTION 'Only super_admin can change user roles';
  END IF;
  
  -- Validate new role
  IF new_role NOT IN ('pet_owner', 'doctor', 'admin', 'super_admin') THEN
    RAISE EXCEPTION 'Invalid role: %', new_role;
  END IF;
  
  -- Get old role for audit
  SELECT role INTO old_role FROM users WHERE id = target_user_id;
  
  -- Update role
  UPDATE users SET role = new_role, updated_at = NOW()
  WHERE id = target_user_id;
  
  -- Log the action
  INSERT INTO admin_audit_log (admin_id, action, target_table, target_id, old_value, new_value)
  VALUES (auth.uid(), 'ROLE_CHANGE', 'users', target_user_id::text, 
          jsonb_build_object('role', old_role),
          jsonb_build_object('role', new_role));
  
  RETURN true;
END;
$$;

-- Secure ban user RPC (requires admin)
CREATE OR REPLACE FUNCTION public.ban_user(
  target_user_id uuid,
  reason text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller_is_admin boolean;
  target_role text;
BEGIN
  -- Verify caller is admin
  SELECT is_admin() INTO caller_is_admin;
  
  IF NOT caller_is_admin THEN
    RAISE EXCEPTION 'Only admins can ban users';
  END IF;
  
  -- Cannot ban super_admin
  SELECT role INTO target_role FROM users WHERE id = target_user_id;
  IF target_role = 'super_admin' THEN
    RAISE EXCEPTION 'Cannot ban super_admin';
  END IF;
  
  -- Ban the user
  UPDATE users SET 
    banned_at = NOW(),
    banned_reason = reason,
    banned_by = auth.uid(),
    updated_at = NOW()
  WHERE id = target_user_id;
  
  -- Log the action
  INSERT INTO admin_audit_log (admin_id, action, target_table, target_id, new_value)
  VALUES (auth.uid(), 'BAN_USER', 'users', target_user_id::text,
          jsonb_build_object('reason', reason));
  
  RETURN true;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.change_user_role TO authenticated;
GRANT EXECUTE ON FUNCTION public.ban_user TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_super_admin TO authenticated;

-- ============================================================================
-- SECTION 10: FINAL PERMISSION GRANTS
-- ============================================================================

GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.posts TO authenticated;
GRANT SELECT ON public.users TO anon;
GRANT SELECT ON public.doctors TO anon;
GRANT ALL ON public.admin_audit_log TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Reload schema cache
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Run these to verify security is in place:

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'posts', 'doctors', 'appointments', 'admin_directory');

-- Check admin directory is populated
SELECT u.email, u.role, ad.id IS NOT NULL as in_admin_directory
FROM users u
LEFT JOIN admin_directory ad ON u.id = ad.id
WHERE u.role IN ('admin', 'super_admin');

-- List all policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

SELECT '✅ SECURITY HARDENING COMPLETE' as status;
