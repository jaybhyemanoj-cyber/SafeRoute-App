-- Migration for SafeRoute AI Phase 4: Automated Trust System & Distinct User Confirmations

-- 1. Extend reports table with confirmations_count and clear_votes_count
ALTER TABLE public.reports
  ADD COLUMN IF NOT EXISTS confirmations_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS clear_votes_count INTEGER NOT NULL DEFAULT 0;

-- 2. CREATE REPORT_VOTES TABLE (Distinct user votes for confirmation / clear)
CREATE TABLE IF NOT EXISTS public.report_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    vote_type TEXT NOT NULL CHECK (vote_type IN ('confirm', 'clear')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_user_report_vote UNIQUE (report_id, user_id)
);

-- Enable RLS on report_votes
ALTER TABLE public.report_votes ENABLE ROW LEVEL SECURITY;

-- Policy: Allow read report votes
CREATE POLICY "Allow read report votes"
ON public.report_votes FOR SELECT
USING (true);

-- Policy: Allow authenticated users to vote, preventing self-vote via check
CREATE POLICY "Allow vote on reports preventing self-vote"
ON public.report_votes FOR INSERT
WITH CHECK (
    auth.uid() IS NOT NULL
    AND auth.uid() = user_id
    AND auth.uid() != (SELECT r.user_id FROM public.reports r WHERE r.id = report_id)
);

-- 3. TRIGGER FUNCTION TO AUTOMATICALLY UPDATE VOTE COUNTS ON REPORTS TABLE
CREATE OR REPLACE FUNCTION public.update_report_vote_counts()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        IF NEW.vote_type = 'confirm' THEN
            UPDATE public.reports
            SET confirmations_count = confirmations_count + 1
            WHERE id = NEW.report_id;
        ELSIF NEW.vote_type = 'clear' THEN
            UPDATE public.reports
            SET clear_votes_count = clear_votes_count + 1
            WHERE id = NEW.report_id;
        END IF;
    ELSIF (TG_OP = 'DELETE') THEN
        IF OLD.vote_type = 'confirm' THEN
            UPDATE public.reports
            SET confirmations_count = GREATEST(0, confirmations_count - 1)
            WHERE id = OLD.report_id;
        ELSIF OLD.vote_type = 'clear' THEN
            UPDATE public.reports
            SET clear_votes_count = GREATEST(0, clear_votes_count - 1)
            WHERE id = OLD.report_id;
        END IF;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS on_report_vote_changed ON public.report_votes;
CREATE TRIGGER on_report_vote_changed
  AFTER INSERT OR DELETE ON public.report_votes
  FOR EACH ROW EXECUTE FUNCTION public.update_report_vote_counts();
