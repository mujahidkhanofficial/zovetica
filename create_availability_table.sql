-- Create availability_slots table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.availability_slots (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    doctor_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
    day text NOT NULL,
    start_time text NOT NULL,
    end_time text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.availability_slots ENABLE ROW LEVEL SECURITY;

-- Allow everything for now (Dev Mode - Fixes "not stored" issue)
CREATE POLICY "Enable all access for availability_slots" ON public.availability_slots
    FOR ALL USING (true) WITH CHECK (true);

-- Ensure RLS doesn't block inserts even if policy is tricky
ALTER TABLE public.availability_slots FORCE ROW LEVEL SECURITY;
