-- Zovetica Admin Fix - The "Recursion Breaker"
-- This separates the list of active admins into a specific table (admin_directory)
-- This guarantees that checking "Am I an admin?" NEVER triggers the "Users" policy, preventing the crash.

-- 1. Create the Admin Directory table
CREATE TABLE IF NOT EXISTS public.admin_directory (
    id uuid REFERENCES auth.users NOT NULL PRIMARY KEY,
    created_at timestamptz DEFAULT now()
);

-- 2. Populate it with existing admins from the users table
INSERT INTO public.admin_directory (id)
SELECT id FROM public.users 
WHERE role IN ('admin', 'super_admin')
ON CONFLICT (id) DO NOTHING;

-- 3. Create a Trigger to keep it in sync automatically
-- When a user's role changes to 'admin', they appear in admin_directory.
-- When they are downgraded, they are removed.

CREATE OR REPLACE FUNCTION public.sync_admin_directory()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.role IN ('admin', 'super_admin') THEN
        INSERT INTO public.admin_directory (id) VALUES (NEW.id)
        ON CONFLICT (id) DO NOTHING;
    ELSE
        DELETE FROM public.admin_directory WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_user_role_change ON public.users;
CREATE TRIGGER on_user_role_change
AFTER INSERT OR UPDATE OF role ON public.users
FOR EACH ROW EXECUTE FUNCTION public.sync_admin_directory();

-- 4. Redefine is_admin() to be SAFE (Queries admin_directory, NOT users)
-- This breaks the infinite loop.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  -- Simply check the directory. No recursion possible.
  SELECT EXISTS (
    SELECT 1 FROM admin_directory WHERE id = auth.uid()
  );
$$;

-- 5. Enable RLS on admin_directory for safety (Only admins can read the full list)
ALTER TABLE public.admin_directory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view directory"
ON public.admin_directory FOR SELECT
USING (auth.uid() IN (SELECT id FROM admin_directory));

-- 6. Re-apply the User Policies (Same as before, but now safe)
-- Drop old ones first to be sure
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Admins can update users" ON public.users;

-- Safe policies
CREATE POLICY "Admins can view all users"
  ON public.users FOR SELECT
  USING (is_admin()); -- Now safe!

CREATE POLICY "Admins can update users"
  ON public.users FOR UPDATE
  USING (is_admin()); -- Now safe!

-- 7. Grant permissions
GRANT SELECT ON public.admin_directory TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- Force schema reload
NOTIFY pgrst, 'reload schema';
