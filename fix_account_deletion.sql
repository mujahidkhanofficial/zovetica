-- ============================================================================
-- SECURE ACCOUNT DELETION - Server-side cleanup & deletion
-- ============================================================================
-- 
-- This script creates a secure RPC function to delete a user's own account.
-- It handles:
-- 1. Cleaning up all related data in the correct order
-- 2. Deleting the user from auth.users (which cascades to public.users)
-- 3. returning success/failure status
--
-- ⚠️ RUN THIS IN SUPABASE SQL EDITOR
-- ============================================================================

-- Function to delete the calling user's account
CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
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

  -- Start deletion process
  -- specific tables that might not have CASCADE DELETE set up correctly
  
  -- 1. Delete notifications (where user is recipient or actor)
  DELETE FROM public.notifications 
  WHERE user_id = v_user_id OR actor_id = v_user_id;

  -- 2. Delete messages sent by user
  DELETE FROM public.messages WHERE sender_id = v_user_id;
  
  -- 3. Delete chat participation
  DELETE FROM public.chat_participants WHERE user_id = v_user_id;
  
  -- 4. Delete social interactions
  DELETE FROM public.post_likes WHERE user_id = v_user_id;
  DELETE FROM public.post_comments WHERE user_id = v_user_id;
  
  -- 5. Delete posts (and their comments/likes via cascade ideally, but explicit here for safety)
  DELETE FROM public.posts WHERE user_id = v_user_id;
  
  -- 6. Delete appointments
  -- As patient
  DELETE FROM public.appointments WHERE user_id = v_user_id;
  -- As pet owner (via checking pet ownership)
  DELETE FROM public.appointments 
  WHERE pet_id IN (SELECT id FROM public.pets WHERE owner_id = v_user_id);
  
  -- 7. Delete pets
  DELETE FROM public.pets WHERE owner_id = v_user_id;
  
  -- 8. Delete friendships
  DELETE FROM public.friendships 
  WHERE user_id = v_user_id OR friend_id = v_user_id;
  
  -- 9. Delete doctor-specific data
  DELETE FROM public.doctor_applications WHERE user_id = v_user_id;
  DELETE FROM public.doctors WHERE id = v_user_id;
  
  -- 10. Delete from public.users (usually cascades, but ensures cleanup)
  DELETE FROM public.users WHERE id = v_user_id;
  
  -- 11. FINALLY: Delete from auth.users
  -- This requires the function to run with SECURITY DEFINER privileges
  -- and the postgres role (or a role with DELETE on auth.users)
  DELETE FROM auth.users WHERE id = v_user_id;

  RETURN json_build_object('success', true, 'message', 'Account deleted successfully');

EXCEPTION WHEN OTHERS THEN
  -- Log error and return failure
  RAISE WARNING 'Account deletion failed for user %: %', v_user_id, SQLERRM;
  RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;

-- Verification
SELECT '✅ Account deletion RPC created' as status;
