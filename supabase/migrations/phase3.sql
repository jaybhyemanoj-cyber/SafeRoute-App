-- Migration for SafeRoute AI Phase 3: AI-Assisted Safety Scoring & Route Selection

-- Extend route_history table with safety analysis metrics
ALTER TABLE public.route_history
  ADD COLUMN IF NOT EXISTS safety_score INTEGER DEFAULT 100,
  ADD COLUMN IF NOT EXISTS hazard_count INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS analysis_version TEXT DEFAULT 'safety_engine_v1';

-- Comment describing the new analysis metrics
COMMENT ON COLUMN public.route_history.safety_score IS 'Calculated route safety score (0-100)';
COMMENT ON COLUMN public.route_history.hazard_count IS 'Number of detected nearby hazard signals along route';
COMMENT ON COLUMN public.route_history.analysis_version IS 'Safety scoring engine version identifier';
