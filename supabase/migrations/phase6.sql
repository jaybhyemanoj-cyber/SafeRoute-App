-- Migration for SafeRoute AI Phase 6: Authentication, User Profiles, User Preferences & Personalization

-- 1. CREATE PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Users read own profile"
ON public.profiles
FOR SELECT
USING (auth.uid() IS NOT NULL AND auth.uid() = id);

CREATE POLICY "Users insert own profile"
ON public.profiles
FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = id);

CREATE POLICY "Users update own profile"
ON public.profiles
FOR UPDATE
USING (auth.uid() IS NOT NULL AND auth.uid() = id);


-- 2. CREATE USER PREFERENCES TABLE
CREATE TABLE IF NOT EXISTS public.user_preferences (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    route_preference_mode TEXT NOT NULL DEFAULT 'balanced' CHECK (route_preference_mode IN ('balanced', 'safety_priority', 'time_priority')),
    avoid_heavy_traffic BOOLEAN NOT NULL DEFAULT false,
    avoid_broken_footpaths BOOLEAN NOT NULL DEFAULT false,
    avoid_construction BOOLEAN NOT NULL DEFAULT false,
    avoid_waterlogging BOOLEAN NOT NULL DEFAULT false,
    avoid_unsafe_crossings BOOLEAN NOT NULL DEFAULT false,
    avoid_road_damage BOOLEAN NOT NULL DEFAULT false,
    avoid_suspicious_activity BOOLEAN NOT NULL DEFAULT false,
    avoid_stray_animals BOOLEAN NOT NULL DEFAULT false,
    alert_sensitivity TEXT NOT NULL DEFAULT 'medium' CHECK (alert_sensitivity IN ('low', 'medium', 'high')),
    ai_insights_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS on user_preferences
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_preferences
CREATE POLICY "Users read own preferences"
ON public.user_preferences
FOR SELECT
USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "Users insert own preferences"
ON public.user_preferences
FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "Users update own preferences"
ON public.user_preferences
FOR UPDATE
USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);


-- 3. AUTOMATIC PROFILE & PREFERENCES CREATION TRIGGER ON AUTH.USERS
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    user_display_name TEXT;
BEGIN
    -- Extract display name from OAuth or email metadata
    user_display_name := COALESCE(
        new.raw_user_meta_data->>'display_name',
        new.raw_user_meta_data->>'full_name',
        new.raw_user_meta_data->>'name',
        split_part(new.email, '@', 1)
    );

    -- Insert default profile
    INSERT INTO public.profiles (id, display_name, created_at, updated_at)
    VALUES (new.id, user_display_name, NOW(), NOW())
    ON CONFLICT (id) DO UPDATE
    SET display_name = EXCLUDED.display_name,
        updated_at = NOW();

    -- Insert default preferences
    INSERT INTO public.user_preferences (
        user_id,
        route_preference_mode,
        avoid_heavy_traffic,
        avoid_broken_footpaths,
        avoid_construction,
        avoid_waterlogging,
        avoid_unsafe_crossings,
        avoid_road_damage,
        avoid_suspicious_activity,
        avoid_stray_animals,
        alert_sensitivity,
        ai_insights_enabled,
        created_at,
        updated_at
    )
    VALUES (
        new.id,
        'balanced',
        false, false, false, false, false, false, false, false,
        'medium',
        true,
        NOW(), NOW()
    )
    ON CONFLICT (user_id) DO NOTHING;

    RETURN new;
END;
$$;

-- Create trigger if not existing
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- 4. PERSONAL DATA DELETION FUNCTION (PRIVACY & GDPR COMPLIANCE)
CREATE OR REPLACE FUNCTION public.delete_user_account_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_user_id UUID := auth.uid();
BEGIN
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Delete user profile, preferences, and route history (community reports remain anonymous)
    DELETE FROM public.profiles WHERE id = current_user_id;
    DELETE FROM public.user_preferences WHERE user_id = current_user_id;
    DELETE FROM public.route_history WHERE user_id = current_user_id;
END;
$$;
