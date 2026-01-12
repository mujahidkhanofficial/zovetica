-- ============================================================================
-- DOCTOR APPLICATION WORKFLOW - Secure Doctor Registration
-- ============================================================================
-- 
-- This migration enables a secure doctor registration flow:
-- 1. Users sign up as pet_owner (existing behavior)
-- 2. If they selected "Doctor", a doctor_application is created
-- 3. Admin reviews and approves/rejects the application
-- 4. Approved users get role upgraded to 'doctor'
--
-- ⚠️ RUN THIS IN SUPABASE SQL EDITOR
-- ============================================================================

-- ============================================================================
-- SECTION 1: CREATE DOCTOR APPLICATIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.doctor_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  specialty text NOT NULL,
  clinic_name text NOT NULL,
  license_number text,  -- Optional: for verification
  years_experience int,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  submitted_at timestamptz DEFAULT now(),
  reviewed_at timestamptz,
  reviewed_by uuid REFERENCES public.users(id),
  rejection_reason text,
  UNIQUE(user_id)  -- One application per user
);

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_doctor_applications_status 
ON public.doctor_applications(status);

CREATE INDEX IF NOT EXISTS idx_doctor_applications_user 
ON public.doctor_applications(user_id);

-- ============================================================================
-- SECTION 2: RLS POLICIES FOR DOCTOR APPLICATIONS
-- ============================================================================

ALTER TABLE public.doctor_applications ENABLE ROW LEVEL SECURITY;

-- Users can view their own applications
DROP POLICY IF EXISTS "Users can view own application" ON public.doctor_applications;
CREATE POLICY "Users can view own application"
ON public.doctor_applications FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can create their own application
DROP POLICY IF EXISTS "Users can submit application" ON public.doctor_applications;
CREATE POLICY "Users can submit application"
ON public.doctor_applications FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid()
  AND status = 'pending'  -- Can only submit pending applications
);

-- Admins can view all applications
DROP POLICY IF EXISTS "Admins can view all applications" ON public.doctor_applications;
CREATE POLICY "Admins can view all applications"
ON public.doctor_applications FOR SELECT
TO authenticated
USING (public.is_admin());

-- Admins can update applications (approve/reject)
DROP POLICY IF EXISTS "Admins can update applications" ON public.doctor_applications;
CREATE POLICY "Admins can update applications"
ON public.doctor_applications FOR UPDATE
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- ============================================================================
-- SECTION 3: FUNCTION TO APPROVE DOCTOR APPLICATION
-- ============================================================================

CREATE OR REPLACE FUNCTION public.approve_doctor_application(
  application_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_specialty text;
  v_clinic text;
BEGIN
  -- Verify caller is admin
  IF NOT public.is_admin() THEN
    RETURN json_build_object('success', false, 'error', 'Only admins can approve applications');
  END IF;

  -- Get application details
  SELECT user_id, specialty, clinic_name 
  INTO v_user_id, v_specialty, v_clinic
  FROM doctor_applications 
  WHERE id = application_id AND status = 'pending';

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Application not found or already processed');
  END IF;

  -- Update application status
  UPDATE doctor_applications 
  SET 
    status = 'approved',
    reviewed_at = now(),
    reviewed_by = auth.uid()
  WHERE id = application_id;

  -- Upgrade user role to doctor and set specialty
  UPDATE users 
  SET 
    role = 'doctor',
    specialty = v_specialty,
    updated_at = now()
  WHERE id = v_user_id;

  -- Create doctor profile if doctors table exists
  BEGIN
    INSERT INTO doctors (id, specialty, clinic, is_available)
    VALUES (v_user_id, v_specialty, v_clinic, true)
    ON CONFLICT (id) DO UPDATE SET
      specialty = EXCLUDED.specialty,
      clinic = EXCLUDED.clinic;
  EXCEPTION WHEN undefined_table THEN
    -- doctors table doesn't exist, skip
    NULL;
  END;

  RETURN json_build_object(
    'success', true, 
    'message', 'Doctor application approved',
    'user_id', v_user_id
  );
END;
$$;

-- ============================================================================
-- SECTION 4: FUNCTION TO REJECT DOCTOR APPLICATION  
-- ============================================================================

CREATE OR REPLACE FUNCTION public.reject_doctor_application(
  application_id uuid,
  reason text DEFAULT 'Application did not meet requirements'
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Verify caller is admin
  IF NOT public.is_admin() THEN
    RETURN json_build_object('success', false, 'error', 'Only admins can reject applications');
  END IF;

  -- Get application
  SELECT user_id INTO v_user_id
  FROM doctor_applications 
  WHERE id = application_id AND status = 'pending';

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Application not found or already processed');
  END IF;

  -- Update application status
  UPDATE doctor_applications 
  SET 
    status = 'rejected',
    reviewed_at = now(),
    reviewed_by = auth.uid(),
    rejection_reason = reason
  WHERE id = application_id;

  RETURN json_build_object(
    'success', true, 
    'message', 'Doctor application rejected',
    'user_id', v_user_id
  );
END;
$$;

-- ============================================================================
-- SECTION 5: FUNCTION TO GET PENDING APPLICATIONS (for admin dashboard)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_pending_doctor_applications()
RETURNS TABLE (
  id uuid,
  user_id uuid,
  user_name text,
  user_email text,
  specialty text,
  clinic_name text,
  submitted_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Verify caller is admin
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can view applications';
  END IF;

  RETURN QUERY
  SELECT 
    da.id,
    da.user_id,
    u.name as user_name,
    u.email as user_email,
    da.specialty,
    da.clinic_name,
    da.submitted_at
  FROM doctor_applications da
  JOIN users u ON da.user_id = u.id
  WHERE da.status = 'pending'
  ORDER BY da.submitted_at ASC;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.approve_doctor_application(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_doctor_application(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pending_doctor_applications() TO authenticated;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'Doctor Application table created' as step, EXISTS(
  SELECT 1 FROM information_schema.tables 
  WHERE table_name = 'doctor_applications'
) as success;

SELECT '✅ DOCTOR APPLICATION WORKFLOW INSTALLED' as status;
