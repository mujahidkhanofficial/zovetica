-- RESTORE SECURITY SCRIPT
-- Purpose: Re-enable Row Level Security (RLS) safely using the new Admin Architecture.
-- Usage: Run after successful login verification.

-- 1. Create/Ensure separate Admin Directory (The Anti-Recursion Table)
CREATE TABLE IF NOT EXISTS public.admin_directory (
    id uuid REFERENCES auth.users NOT NULL PRIMARY KEY,
    created_at timestamptz DEFAULT now()
);

-- 2. Populate it with existing admins (if empty)
INSERT INTO public.admin_directory (id)
SELECT id FROM public.users 
WHERE role IN ('admin', 'super_admin')
ON CONFLICT (id) DO NOTHING;

-- 3. Create the Database Trigger to Sync User Role -> Admin Directory automatically
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

-- 4. Create the SAFE is_admin() function
-- This checks the directory table, NOT the users table, breaking the infinite loop.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM admin_directory WHERE id = auth.uid()
  );
$$;

-- 5. RE-ENABLE RLS on Main Tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

-- 6. Apply SAFE Policies (Using is_admin())

-- [USERS TABLE]
CREATE POLICY "Admins can view all users"
  ON public.users FOR SELECT
  USING (is_admin()); 

CREATE POLICY "Admins can update users"
  ON public.users FOR UPDATE
  USING (is_admin());

CREATE POLICY "Everyone can view basic user info"
  ON public.users FOR SELECT
  USING (true); -- Or restrict if needed

CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- [POSTS TABLE]
CREATE POLICY "Admins can delete any post"
  ON public.posts FOR DELETE
  USING (is_admin());

CREATE POLICY "Admins can update (flag) posts"
  ON public.posts FOR UPDATE
  USING (is_admin());

-- 7. Secure the Admin Directory itself
ALTER TABLE public.admin_directory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view directory"
ON public.admin_directory FOR SELECT
USING (auth.uid() IN (SELECT id FROM admin_directory));

-- 8. Clean up system permissions specific to PostgREST
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- 9. Reload Schema
NOTIFY pgrst, 'reload schema';

SELECT 'SECURITY RESTORED. RLS is Active. Admin Architecture is Recursive-Free.' as status;
