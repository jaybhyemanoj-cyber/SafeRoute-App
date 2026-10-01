-- ========================================================
-- SAFEROUTE AI — PHASE 2 COMPLETE SUPABASE SQL SCHEMA
-- Project Reference: atvsoklmuynqjpbfmzoe
-- ========================================================

-- 1. ENABLE REQUIRED EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 2. CREATE REPORTS TABLE (Community Pedestrian Safety/Hazard Reports)
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID DEFAULT auth.uid(),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    hazard_type TEXT NOT NULL CHECK (
        hazard_type IN (
            'poor_lighting',
            'broken_footpath',
            'road_damage',
            'construction',
            'unsafe_crossing',
            'heavy_traffic',
            'waterlogging',
            'suspicious_activity',
            'stray_animals',
            'other'
        )
    ),
    description TEXT,
    photo_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'expired')),
    confidence DOUBLE PRECISION NOT NULL DEFAULT 0.5,
    location GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
    ) STORED
);

-- 3. CREATE ROUTE HISTORY TABLE (Walking Route Logs for Safety Analysis)
CREATE TABLE IF NOT EXISTS public.route_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID DEFAULT auth.uid(),
    start_latitude DOUBLE PRECISION NOT NULL,
    start_longitude DOUBLE PRECISION NOT NULL,
    end_latitude DOUBLE PRECISION NOT NULL,
    end_longitude DOUBLE PRECISION NOT NULL,
    distance_meters DOUBLE PRECISION,
    duration_seconds INTEGER,
    route_geometry JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. EFFICIENT INDEXES FOR GEOGRAPHIC & SEARCH QUERIES
CREATE INDEX IF NOT EXISTS idx_reports_lat_lon 
ON public.reports (latitude, longitude);

CREATE INDEX IF NOT EXISTS idx_reports_status_created 
ON public.reports (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_reports_spatial_location 
ON public.reports USING GIST (location);

CREATE INDEX IF NOT EXISTS idx_route_history_user_created 
ON public.route_history (user_id, created_at DESC);

-- 5. POSTGIS RPC FUNCTION FOR NEARBY HAZARD QUERIES
CREATE OR REPLACE FUNCTION public.get_nearby_reports(
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    radius_meters DOUBLE PRECISION DEFAULT 3000
)
RETURNS SETOF public.reports
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT *
    FROM public.reports
    WHERE status = 'active'
      AND ST_DWithin(
          location,
          ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
          radius_meters
      )
    ORDER BY created_at DESC;
$$;

-- 6. ROW LEVEL SECURITY (RLS) POLICIES — REPORTS TABLE
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Policy: Allow public read access to active hazard reports
CREATE POLICY "Allow public read active reports"
ON public.reports
FOR SELECT
USING (status = 'active');

-- Policy: Allow anonymous & authenticated users to submit hazard reports
CREATE POLICY "Allow public report submission"
ON public.reports
FOR INSERT
WITH CHECK (true);

-- Policy: Allow users to update their own reports
CREATE POLICY "Allow users update own reports"
ON public.reports
FOR UPDATE
USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- Policy: Allow users to delete their own reports
CREATE POLICY "Allow users delete own reports"
ON public.reports
FOR DELETE
USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);


-- 7. ROW LEVEL SECURITY (RLS) POLICIES — ROUTE_HISTORY TABLE
ALTER TABLE public.route_history ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only read their own route history
CREATE POLICY "Users read own route history"
ON public.route_history
FOR SELECT
USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- Policy: Users can insert their own route history
CREATE POLICY "Users insert own route history"
ON public.route_history
FOR INSERT
WITH CHECK (user_id IS NULL OR auth.uid() = user_id);


-- 8. SUPABASE STORAGE BUCKET CONFIGURATION & POLICIES
-- Create storage bucket 'hazard-reports' if not existing
INSERT INTO storage.buckets (id, name, public)
VALUES ('hazard-reports', 'hazard-reports', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policy: Public Read Access for report images
CREATE POLICY "Public Read Hazard Images"
ON storage.objects
FOR SELECT
USING (bucket_id = 'hazard-reports');

-- Storage Policy: Public Upload Access for report images
CREATE POLICY "Public Upload Hazard Images"
ON storage.objects
FOR INSERT
WITH CHECK (bucket_id = 'hazard-reports');
