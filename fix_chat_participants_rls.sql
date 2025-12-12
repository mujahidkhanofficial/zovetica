-- Fix for "infinite recursion" error in chat_participants table
-- Run this in your Supabase SQL Editor

-- STEP 1: Drop existing problematic policies
DROP POLICY IF EXISTS "View chat participants" ON public.chat_participants;
DROP POLICY IF EXISTS "Users can view their own participations" ON public.chat_participants;
DROP POLICY IF EXISTS "Enable read access for users based on user_id" ON public.chat_participants;

-- STEP 2: Create simple, non-recursive policies

-- Policy 1: Users can see their own chat participations
CREATE POLICY "Users can view own participations"
ON public.chat_participants
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Policy 2: Users can see other participants in their chats
-- This is the critical one - it must NOT reference chat_participants recursively
CREATE POLICY "Users can view chat members"
ON public.chat_participants
FOR SELECT
TO authenticated
USING (
  chat_id IN (
    SELECT cp.chat_id 
    FROM public.chat_participants cp
    WHERE cp.user_id = auth.uid()
  )
);

-- STEP 3: Enable RLS on the table (if not already enabled)
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;

-- STEP 4: Verify policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'chat_participants';
