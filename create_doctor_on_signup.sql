-- ============================================================================
-- FIX: Doctor Role on Signup
-- ============================================================================
-- This function securely promotes a user to doctor role after email verification.
-- It bypasses RLS using SECURITY DEFINER since users cannot update their own role.
-- ============================================================================

-- Create the RPC function
CREATE OR REPLACE FUNCTION public.create_doctor_on_signup(
  p_specialty text,
  p_clinic text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_doctor_id uuid;
BEGIN
  -- Get the authenticated user's ID
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  -- Check if user already has doctor role
  IF EXISTS (SELECT 1 FROM users WHERE id = v_user_id AND role = 'doctor') THEN
    RETURN json_build_object('success', true, 'message', 'Already a doctor');
  END IF;
  
  -- Check if doctor record already exists
  IF EXISTS (SELECT 1 FROM doctors WHERE user_id = v_user_id) THEN
    -- Just update the role if doctor record exists but role is wrong
    UPDATE users SET role = 'doctor', updated_at = NOW() WHERE id = v_user_id;
    RETURN json_build_object('success', true, 'message', 'Role updated to doctor');
  END IF;
  
  -- Update user role to doctor
  UPDATE users 
  SET role = 'doctor', 
      specialty = p_specialty,
      updated_at = NOW()
  WHERE id = v_user_id;
  
  -- Create doctor record
  INSERT INTO doctors (user_id, specialty, clinic, available, verified)
  VALUES (v_user_id, p_specialty, p_clinic, true, true)
  RETURNING id INTO v_doctor_id;
  
  RETURN json_build_object(
    'success', true, 
    'message', 'Doctor created successfully',
    'doctor_id', v_doctor_id
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.create_doctor_on_signup(text, text) TO authenticated;

-- Verification
SELECT 'create_doctor_on_signup function created' as status;
