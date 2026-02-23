-- Easypaisa Payment & Wallet System Migration

-- 1. Update Appointments Table (add columns if missing)
ALTER TABLE public.appointments
ADD COLUMN IF NOT EXISTS payment_ref_id text;
ALTER TABLE public.appointments
ADD COLUMN IF NOT EXISTS payment_status text DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'paid_to_platform', 'refunded', 'completed', 'pending_admin'));
ALTER TABLE public.appointments
ADD COLUMN IF NOT EXISTS platform_fee numeric DEFAULT 0;
ALTER TABLE public.appointments
ADD COLUMN IF NOT EXISTS vet_earnings numeric DEFAULT 0;
ALTER TABLE public.appointments
ADD COLUMN IF NOT EXISTS payment_method text DEFAULT 'easypaisa';
ALTER TABLE public.appointments
ADD COLUMN IF NOT EXISTS payment_confirmed_by_user boolean DEFAULT false;
ALTER TABLE public.appointments
ADD COLUMN IF NOT EXISTS payment_confirmed_by_admin boolean DEFAULT false;
ALTER TABLE public.appointments
ADD COLUMN IF NOT EXISTS payment_screenshot_url text; -- optional link to user-uploaded proof

-- 2. Update Users Table for Wallet (since doctors are stored in the users table)
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS easypaisa_account_number text;
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS wallet_balance numeric DEFAULT 0;

-- 3. Create Payouts Table for Vet Withdrawals
CREATE TABLE IF NOT EXISTS public.payouts (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    doctor_id uuid NOT NULL REFERENCES public.users(id),
    amount numeric NOT NULL,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    easypaisa_transaction_id text,
    requested_at timestamp with time zone DEFAULT now(),
    processed_at timestamp with time zone
);

-- 4. Create Wallet Transactions Table (Ledger for transparency)
CREATE TABLE IF NOT EXISTS public.wallet_transactions (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    doctor_id uuid REFERENCES public.users(id),
    user_id uuid REFERENCES public.users(id),
    appointment_id uuid REFERENCES public.appointments(id),
    payout_id uuid REFERENCES public.payouts(id),
    type text NOT NULL CHECK (type IN ('credit', 'debit')),
    amount numeric NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now()
);

-- 5. RLS Policies for new tables
ALTER TABLE public.payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;

-- Doctors & users can view their own wallet transactions
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'wallet_transactions' AND policyname = 'Users can view their own wallet transactions'
    ) THEN
        CREATE POLICY "Users can view their own wallet transactions" ON public.wallet_transactions
            FOR SELECT USING (
                  doctor_id = auth.uid()
               OR user_id = auth.uid()
            );
    END IF;
END$$;

-- Doctors can view their own payouts
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'payouts' AND policyname = 'Doctors can view their own payouts'
    ) THEN
        CREATE POLICY "Doctors can view their own payouts" ON public.payouts
            FOR SELECT USING (doctor_id = auth.uid());
    END IF;
END$$;

-- Doctors can insert payout requests
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'payouts' AND policyname = 'Doctors can request payouts'
    ) THEN
        CREATE POLICY "Doctors can request payouts" ON public.payouts
            FOR INSERT WITH CHECK (doctor_id = auth.uid());
    END IF;
END$$;
