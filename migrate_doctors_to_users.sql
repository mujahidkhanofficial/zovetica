-- Migrate Doctor Role and Clean up Schema
-- This script merges doctor-specific fields from the 'doctors' table into the 'users' table 
-- and updates foreign keys to use public.users(id) instead of public.doctors(id).

-- 1. Ensure 'users' table has all necessary fields (should already have them based on schema.sql)
-- specialty, clinic, rating, reviews_count already exist in public.users.

-- 2. Migrate existing data from doctors table to users table (if any)
UPDATE public.users u
SET 
  specialty = d.specialty,
  clinic = d.clinic,
  rating = d.rating,
  reviews_count = d.reviews_count
FROM public.doctors d
WHERE u.id = d.user_id
AND u.role = 'doctor';

-- 3. Update appointments table to reference users directly
-- First, drop the old foreign key
ALTER TABLE IF EXISTS public.appointments 
DROP CONSTRAINT IF EXISTS appointments_doctor_id_fkey;

-- Since doctor_id in appointments currently contains public.doctors(id), 
-- we need to update it to contain public.users(id)
UPDATE public.appointments a
SET doctor_id = d.user_id
FROM public.doctors d
WHERE a.doctor_id = d.id;

-- Add new foreign key pointing to users
ALTER TABLE public.appointments
ADD CONSTRAINT appointments_doctor_id_fkey 
FOREIGN KEY (doctor_id) REFERENCES public.users(id);

-- 4. Update availability_slots table to reference users directly
ALTER TABLE IF EXISTS public.availability_slots
DROP CONSTRAINT IF EXISTS availability_slots_doctor_id_fkey;

UPDATE public.availability_slots s
SET doctor_id = d.user_id
FROM public.doctors d
WHERE s.doctor_id = d.id;

ALTER TABLE public.availability_slots
ADD CONSTRAINT availability_slots_doctor_id_fkey 
FOREIGN KEY (doctor_id) REFERENCES public.users(id);

-- 5. Drop the redundant tables
DROP TABLE IF EXISTS public.doctors CASCADE;
DROP TABLE IF EXISTS public.doctor_applications CASCADE;

-- 6. Update RLS policies for users to allow doctors to manage their own specialty/clinic
-- (This is already covered by "Users can update own non-privileged fields" in security_hardening.sql)

-- 7. Add a policy for everyone to view doctor-specific info in users table
CREATE POLICY "Anyone can view doctor profiles"
  ON public.users FOR SELECT
  USING (role = 'doctor' OR id = auth.uid() OR (SELECT is_admin()));

-- 8. Ensure verified doctors are easily identifiable (optional: add a verified column to users)
-- ALTER TABLE public.users ADD COLUMN IF NOT EXISTS verified boolean DEFAULT true;
