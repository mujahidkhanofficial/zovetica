-- ============================================================================
-- ZOVETICA MESSAGING SECURITY FIX
-- ============================================================================
-- Purpose: Fix critical RLS vulnerabilities in messaging tables
-- 
-- CRITICAL FIXES:
-- 1. Enable RLS on messages, chats, chat_participants
-- 2. Create anti-recursion helper function
-- 3. Add proper RLS policies for all messaging operations
-- 4. Add server-side participant validation trigger
-- 5. Add idempotency key support for message deduplication
--
-- ⚠️ RUN THIS IN SUPABASE SQL EDITOR
-- ============================================================================

-- ============================================================================
-- SECTION 1: SCHEMA UPDATES (Idempotency Key)
-- ============================================================================

-- Add client_message_id for idempotency (prevents duplicate sends on retry)
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS client_message_id uuid;

-- Add unique constraint for idempotency
-- (chat_id, client_message_id) must be unique
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'messages_chat_client_id_unique'
    ) THEN
        ALTER TABLE public.messages 
        ADD CONSTRAINT messages_chat_client_id_unique 
        UNIQUE (chat_id, client_message_id);
    END IF;
END
$$;

-- Add delivery state columns
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS status text DEFAULT 'sent' 
    CHECK (status IN ('pending', 'sent', 'delivered', 'read', 'failed'));
    
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS delivered_at timestamptz;

ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS read_at timestamptz;

-- ============================================================================
-- SECTION 2: ANTI-RECURSION HELPER FUNCTION
-- ============================================================================
-- This function avoids RLS recursion by using SECURITY DEFINER
-- It returns chat IDs the user participates in

CREATE OR REPLACE FUNCTION public.get_user_chat_ids(user_uuid uuid)
RETURNS SETOF integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT chat_id FROM chat_participants WHERE user_id = user_uuid;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.get_user_chat_ids(uuid) TO authenticated;

-- Helper to check if user is in a specific chat
CREATE OR REPLACE FUNCTION public.is_chat_participant(check_user_id uuid, check_chat_id integer)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM chat_participants 
    WHERE user_id = check_user_id AND chat_id = check_chat_id
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_chat_participant(uuid, integer) TO authenticated;

-- ============================================================================
-- SECTION 3: ENABLE RLS ON ALL MESSAGING TABLES
-- ============================================================================

ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- SECTION 4: CHATS TABLE RLS POLICIES
-- ============================================================================

-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view chats they participate in" ON public.chats;
DROP POLICY IF EXISTS "Users can create chats" ON public.chats;
DROP POLICY IF EXISTS "Users can update chats they participate in" ON public.chats;
DROP POLICY IF EXISTS "Users can delete chats they participate in" ON public.chats;

-- SELECT: Users can only view chats they participate in
CREATE POLICY "Users can view chats they participate in"
ON public.chats FOR SELECT
TO authenticated
USING (
  id IN (SELECT get_user_chat_ids(auth.uid()))
);

-- INSERT: Any authenticated user can create a chat
-- (participant validation happens on chat_participants insert)
CREATE POLICY "Users can create chats"
ON public.chats FOR INSERT
TO authenticated
WITH CHECK (true);

-- UPDATE: Users can update chats they participate in
CREATE POLICY "Users can update chats they participate in"
ON public.chats FOR UPDATE
TO authenticated
USING (
  id IN (SELECT get_user_chat_ids(auth.uid()))
)
WITH CHECK (
  id IN (SELECT get_user_chat_ids(auth.uid()))
);

-- DELETE: Users can delete chats they participate in
CREATE POLICY "Users can delete chats they participate in"
ON public.chats FOR DELETE
TO authenticated
USING (
  id IN (SELECT get_user_chat_ids(auth.uid()))
);

-- ============================================================================
-- SECTION 5: CHAT_PARTICIPANTS TABLE RLS POLICIES
-- ============================================================================

-- Drop existing broken policies
DROP POLICY IF EXISTS "Users can view own participations" ON public.chat_participants;
DROP POLICY IF EXISTS "Users can view chat members" ON public.chat_participants;
DROP POLICY IF EXISTS "View chat participants" ON public.chat_participants;
DROP POLICY IF EXISTS "Users can view their own participations" ON public.chat_participants;
DROP POLICY IF EXISTS "Enable read access for users based on user_id" ON public.chat_participants;

-- SELECT: Users can view their own participations
CREATE POLICY "Users can view own participations"
ON public.chat_participants FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- SELECT: Users can view other participants in chats they're in
CREATE POLICY "Users can view fellow participants"
ON public.chat_participants FOR SELECT
TO authenticated
USING (
  chat_id IN (SELECT get_user_chat_ids(auth.uid()))
);

-- INSERT: Users can only add themselves to a chat
-- (for private chats, the creator adds both participants atomically)
CREATE POLICY "Users can add themselves to chats"
ON public.chat_participants FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid()
  OR 
  -- Allow adding others if you're the chat creator (first participant)
  -- This supports the pattern: create chat, then add both participants
  NOT EXISTS (
    SELECT 1 FROM chat_participants WHERE chat_id = chat_participants.chat_id
  )
);

-- DELETE: Users can remove themselves from chats
CREATE POLICY "Users can leave chats"
ON public.chat_participants FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- ============================================================================
-- SECTION 6: MESSAGES TABLE RLS POLICIES
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view messages in their chats" ON public.messages;
DROP POLICY IF EXISTS "Users can send messages to their chats" ON public.messages;
DROP POLICY IF EXISTS "Users can update own messages" ON public.messages;
DROP POLICY IF EXISTS "Users can delete own messages" ON public.messages;

-- SELECT: Users can only view messages in chats they participate in
CREATE POLICY "Users can view messages in their chats"
ON public.messages FOR SELECT
TO authenticated
USING (
  chat_id IN (SELECT get_user_chat_ids(auth.uid()))
);

-- INSERT: Users can only send messages if:
-- 1. They are the sender (sender_id = auth.uid())
-- 2. They are a participant in the chat
CREATE POLICY "Users can send messages to their chats"
ON public.messages FOR INSERT
TO authenticated
WITH CHECK (
  sender_id = auth.uid()
  AND chat_id IN (SELECT get_user_chat_ids(auth.uid()))
);

-- UPDATE: Users can only update their own messages
CREATE POLICY "Users can update own messages"
ON public.messages FOR UPDATE
TO authenticated
USING (sender_id = auth.uid())
WITH CHECK (
  sender_id = auth.uid()
  -- Cannot change sender_id or chat_id
  AND sender_id = (SELECT sender_id FROM messages WHERE id = messages.id)
  AND chat_id = (SELECT chat_id FROM messages WHERE id = messages.id)
);

-- DELETE: Users can only delete their own messages
CREATE POLICY "Users can delete own messages"
ON public.messages FOR DELETE
TO authenticated
USING (sender_id = auth.uid());

-- ============================================================================
-- SECTION 7: SERVER-SIDE TIMESTAMP ENFORCEMENT
-- ============================================================================

-- Trigger to enforce server-side timestamps (prevent client timestamp spoofing)
CREATE OR REPLACE FUNCTION public.enforce_message_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  -- Always use server time for created_at
  IF TG_OP = 'INSERT' THEN
    NEW.created_at := now();
    NEW.status := COALESCE(NEW.status, 'sent');
  END IF;
  
  -- Always use server time for edited_at on updates
  IF TG_OP = 'UPDATE' AND NEW.content != OLD.content THEN
    NEW.edited_at := now();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS enforce_message_timestamps_trigger ON public.messages;
CREATE TRIGGER enforce_message_timestamps_trigger
BEFORE INSERT OR UPDATE ON public.messages
FOR EACH ROW EXECUTE FUNCTION public.enforce_message_timestamps();

-- ============================================================================
-- SECTION 8: PARTICIPANT VALIDATION TRIGGER
-- ============================================================================

-- This trigger provides an extra layer of security by validating
-- that the sender is actually a participant before allowing insert
-- (defense in depth - RLS should catch this, but this is a backup)

CREATE OR REPLACE FUNCTION public.validate_message_sender()
RETURNS TRIGGER AS $$
BEGIN
  -- Verify sender is a participant in the chat
  IF NOT EXISTS (
    SELECT 1 FROM chat_participants 
    WHERE chat_id = NEW.chat_id AND user_id = NEW.sender_id
  ) THEN
    RAISE EXCEPTION 'Sender is not a participant in this chat'
      USING ERRCODE = '42501'; -- insufficient_privilege
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS validate_message_sender_trigger ON public.messages;
CREATE TRIGGER validate_message_sender_trigger
BEFORE INSERT ON public.messages
FOR EACH ROW EXECUTE FUNCTION public.validate_message_sender();

-- ============================================================================
-- SECTION 9: INDEXES FOR PERFORMANCE
-- ============================================================================

-- Composite index for efficient message ordering queries
CREATE INDEX IF NOT EXISTS idx_messages_chat_created 
ON public.messages (chat_id, created_at DESC);

-- Index for sender lookups (edit/delete own messages)
CREATE INDEX IF NOT EXISTS idx_messages_sender 
ON public.messages (sender_id);

-- Index for participant lookups
CREATE INDEX IF NOT EXISTS idx_chat_participants_user 
ON public.chat_participants (user_id);

CREATE INDEX IF NOT EXISTS idx_chat_participants_chat 
ON public.chat_participants (chat_id);

-- ============================================================================
-- SECTION 10: GRANT PERMISSIONS
-- ============================================================================

-- Ensure proper grants
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.chats TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.chat_participants TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.messages TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Reload schema cache
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('messages', 'chats', 'chat_participants');

-- List all messaging policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('messages', 'chats', 'chat_participants')
ORDER BY tablename, policyname;

SELECT '✅ MESSAGING SECURITY FIX COMPLETE' as status;
