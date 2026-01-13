-- ============================================================================
-- SECURE ACCOUNT DELETION - Server-side cleanup & deletion
-- ============================================================================
-- 
-- This script creates a secure RPC function to delete a user's own account.
-- It handles:
-- 1. Cleaning up all related data in the correct order to avoid FK violations
-- 2. Deleting the user from public.users profile
-- 3. Deleting the user from auth.users (killing their identity)
-- 4. Returning success/failure status
--
-- ⚠️ RUN THIS IN SUPABASE SQL EDITOR
-- ============================================================================

-- Function to delete the calling user's account
CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();
  
  -- Verify user is logged in
  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  -- Start deletion process in order that respects Foreign Key constraints
  
  -- 1. Notifications (where user is recipient or actor)
  DELETE FROM public.notifications 
  WHERE user_id = v_user_id OR actor_id = v_user_id;

  -- 2. Messages & Chat Participation
  DELETE FROM public.messages WHERE sender_id = v_user_id;
  DELETE FROM public.chat_participants WHERE user_id = v_user_id;
  
  -- 3. Social Interactions (Likes & Comments)
  DELETE FROM public.comment_likes WHERE user_id = v_user_id;
  DELETE FROM public.post_likes WHERE user_id = v_user_id;
  DELETE FROM public.post_comments WHERE user_id = v_user_id;
  
  -- 4. Community Posts (Images will stay in storage but DB records go)
  DELETE FROM public.posts WHERE user_id = v_user_id;
  
  -- 5. Appointments & Pets
  -- Delete health events associated with the user's pets
  DELETE FROM public.pet_health_events 
  WHERE pet_id IN (SELECT id FROM public.pets WHERE owner_id = v_user_id);
  
  -- Delete appointments (as patient OR for their pets)
  DELETE FROM public.appointments 
  WHERE user_id = v_user_id 
     OR pet_id IN (SELECT id FROM public.pets WHERE owner_id = v_user_id);
  
  -- Delete pets
  DELETE FROM public.pets WHERE owner_id = v_user_id;
  
  -- 6. Social Network (Friendships)
  -- Fixing column names: requester_id and receiver_id
  DELETE FROM public.friendships 
  WHERE requester_id = v_user_id OR receiver_id = v_user_id;
  
  -- 7. Reviews
  -- Delete reviews written BY the user
  DELETE FROM public.reviews WHERE user_id = v_user_id;
  -- Delete reviews written FOR the user (if they were a doctor)
  DELETE FROM public.reviews WHERE doctor_id = v_user_id;

  -- 8. Doctor-specific Data
  -- Delete availability slots (doctor_id is now the user_id)
  DELETE FROM public.availability_slots WHERE doctor_id = v_user_id;

  -- 9. App Preferences & Logging
  DELETE FROM public.notification_preferences WHERE user_id = v_user_id;
  DELETE FROM public.admin_directory WHERE id = v_user_id;
  DELETE FROM public.admin_audit_log WHERE admin_id = v_user_id;
  
  -- 10. Public User Profile (This usually cascades but explicit cleanup is safer)
  DELETE FROM public.users WHERE id = v_user_id;
  
  -- 11. FINALLY: Delete from auth.users (Permanent identity deletion)
  -- Requires SECURITY DEFINER and high privileges
  DELETE FROM auth.users WHERE id = v_user_id;

  RETURN json_build_object('success', true, 'message', 'Account and all data deleted successfully');

EXCEPTION WHEN OTHERS THEN
  -- Log error safely and return failure
  -- In production, consider logging purely on server side
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;

-- Verification
SELECT '✅ Comprehensive Account Deletion RPC created successfully' as status;
