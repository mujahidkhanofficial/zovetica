-- Safely enable Realtime for chat tables
-- Run this in Supabase SQL Editor

-- Create publication if it doesn't exist (Supabase usually has it)
DO $$
BEGIN
    if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
        create publication supabase_realtime;
    end if;
END
$$;

-- Add tables to the publication (Ignore errors if already added)
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE chats;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_participants;

-- Note: You might see an error if the table is already in the publication.
-- That is fine. The goal is to ensure they ARE in it.
