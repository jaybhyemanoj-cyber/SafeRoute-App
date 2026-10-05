-- Migration for SafeRoute AI Emergency Contacts Storage (Firebase Auth UID Schema)

CREATE TABLE IF NOT EXISTS public.emergency_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    contact_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    relationship TEXT DEFAULT 'Parent',
    is_primary BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast user_id lookup
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user_id ON public.emergency_contacts(user_id);

-- Enable RLS on emergency_contacts table
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;

-- Anonymous/App Client Access Policies (Firebase UID ownership checked at application layer)
CREATE POLICY "Allow read emergency contacts by user_id"
ON public.emergency_contacts
FOR SELECT
USING (true);

CREATE POLICY "Allow insert emergency contacts"
ON public.emergency_contacts
FOR INSERT
WITH CHECK (true);

CREATE POLICY "Allow update emergency contacts"
ON public.emergency_contacts
FOR UPDATE
USING (true);

CREATE POLICY "Allow delete emergency contacts"
ON public.emergency_contacts
FOR DELETE
USING (true);
