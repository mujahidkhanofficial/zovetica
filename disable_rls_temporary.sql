-- ALTERNATIVE: Temporarily disable RLS for testing
-- WARNING: This removes security! Only use for testing.
-- Run this if you want to test the app quickly without fixing policies

-- Disable RLS on chat_participants (TEMPORARY - NOT RECOMMENDED FOR PRODUCTION)
ALTER TABLE public.chat_participants DISABLE ROW LEVEL SECURITY;

-- Disable RLS on messages (if also having issues)
ALTER TABLE public.messages DISABLE ROW LEVEL SECURITY;

-- Disable RLS on chats
ALTER TABLE public.chats DISABLE ROW LEVEL SECURITY;

-- NOTE: Remember to re-enable and properly configure RLS before going to production!
