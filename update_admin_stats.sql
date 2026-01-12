-- ============================================================================
-- UPDATE ADMIN STATS RPC
-- ============================================================================
-- This updates the get_admin_stats() function to accurately count pending
-- doctor applications from the new doctor_applications table.
-- ============================================================================

CREATE OR REPLACE FUNCTION get_admin_stats()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result json;
BEGIN
  -- Only allow admins to call this
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND role IN ('admin', 'super_admin')
  ) THEN
    RETURN '{}'::json;
  END IF;

  SELECT json_build_object(
    'total_users', (SELECT COUNT(*) FROM users),
    'total_doctors', (SELECT COUNT(*) FROM doctors),
    'verified_doctors', (SELECT COUNT(*) FROM doctors WHERE verified = true),
    'pending_doctors', (SELECT COUNT(*) FROM doctor_applications WHERE status = 'pending'), -- ✅ Updated source
    'total_pets', (SELECT COUNT(*) FROM pets),
    'total_appointments', (SELECT COUNT(*) FROM appointments),
    'pending_appointments', (SELECT COUNT(*) FROM appointments WHERE status = 'pending'),
    'total_posts', (SELECT COUNT(*) FROM posts),
    'flagged_posts', (SELECT COUNT(*) FROM posts WHERE is_flagged = true),
    'banned_users', (SELECT COUNT(*) FROM users WHERE banned_at IS NOT NULL)
  ) INTO result;
  
  RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_admin_stats() TO authenticated;

SELECT '✅ get_admin_stats updated with doctor_applications count' as status;
