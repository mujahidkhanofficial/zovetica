-- System Audit Script
-- Lists all Triggers and Functions to identify hidden logic hooks.

SELECT 
    event_object_schema as table_schema,
    event_object_table as table_name,
    trigger_schema,
    trigger_name,
    string_agg(event_manipulation, ',') as events,
    action_timing as timing,
    action_statement as definition
FROM information_schema.triggers
GROUP BY 1,2,3,4,6,7
ORDER BY table_schema, table_name;

-- Also check for Event Triggers (DDL hooks)
SELECT evtname, evtevent, evtowner::regrole, evtfoid::regproc
FROM pg_event_trigger;

-- Check for specific hooks on auth.users if possible (requires high privilege, but worth a try)
-- Note: 'auth' schema might not be visible to 'postgres' role in Supabase API depending on config.
SELECT * FROM information_schema.triggers WHERE event_object_schema = 'auth';
