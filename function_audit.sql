-- Function Audit Script
-- Lists all functions in 'public' schema to find potential Auth Hooks.

SELECT 
  routines.routine_name,
  routines.data_type as return_type,
  routines.security_type,
  routine_definition
FROM information_schema.routines
WHERE routines.specific_schema = 'public'
ORDER BY routine_name;

-- Check if 'admin_directory' exists and has entries
SELECT count(*) as admin_count FROM public.admin_directory;
