-- Migration 02: users, profiles, personal_profiles, business_profiles,
-- business_hours, interests.
--
-- This is the identity layer. `public.users` is paired 1:1 with
-- `auth.users` (Supabase's built-in auth table) via a trigger that fires
-- after auth signup. A user can have one PERSONAL and one BUSINESS profile
-- concurrently (enforced by the UNIQUE(user_id, profile_type) constraint).

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.users (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  serial_id       TEXT UNIQUE NOT NULL,
  email           CITEXT UNIQUE NOT NULL,
  phone           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen_at    TIMESTAMPTZ,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_users_serial_id ON public.users(serial_id);
CREATE INDEX IF NOT EXISTS idx_users_email     ON public.users(email);

DROP TRIGGER IF EXISTS trg_users_updated_at ON public.users;
CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Bridge trigger: when Supabase Auth creates a user, mirror it in public.users.
-- SECURITY DEFINER so it runs with elevated privileges. We pin search_path to
-- a deliberate allowlist (`public, extensions, pg_temp`) for two reasons:
--   1. Defense in depth against search_path hijack attacks (no user schemas).
--   2. The chained call into generate_serial_id() needs `extensions` so any
--      pgcrypto/uuid-ossp helper it uses resolves cleanly.
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
BEGIN
  INSERT INTO public.users (id, serial_id, email, phone)
  VALUES (
    NEW.id,
    public.generate_serial_id(),
    COALESCE(NEW.email, NEW.id::text || '@anonymous.beepbip')::citext,
    NEW.phone
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users;
CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- ---------------------------------------------------------------------------
-- profiles (shared fields across personal & business)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  profile_type         public.profile_type NOT NULL,
  subscription_tier    public.subscription_tier NOT NULL DEFAULT 'free',
  visibility_status    public.visibility_status NOT NULL DEFAULT 'open',
  location_sharing     public.location_sharing NOT NULL DEFAULT 'dont_share',
  is_profile_complete  BOOLEAN NOT NULL DEFAULT FALSE,
  is_verified          BOOLEAN NOT NULL DEFAULT FALSE,
  is_founding_business BOOLEAN NOT NULL DEFAULT FALSE,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, profile_type)
);

CREATE INDEX IF NOT EXISTS idx_profiles_user_id    ON public.profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_type       ON public.profiles(profile_type);
CREATE INDEX IF NOT EXISTS idx_profiles_visibility ON public.profiles(visibility_status);
CREATE INDEX IF NOT EXISTS idx_profiles_tier       ON public.profiles(subscription_tier);

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- personal_profiles
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.personal_profiles (
  id              UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  phone           TEXT,
  photo_url       TEXT,
  bio             TEXT,
  interests       TEXT[] NOT NULL DEFAULT '{}',
  social_handles  JSONB NOT NULL DEFAULT '{}'::jsonb,   -- {instagram, tiktok, x, website}
  date_of_birth   DATE,
  gender          TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_personal_profiles_interests
  ON public.personal_profiles USING GIN(interests);

DROP TRIGGER IF EXISTS trg_personal_profiles_updated_at ON public.personal_profiles;
CREATE TRIGGER trg_personal_profiles_updated_at
  BEFORE UPDATE ON public.personal_profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- business_profiles
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.business_profiles (
  id              UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  business_name   TEXT NOT NULL,
  logo_url        TEXT,
  cover_url       TEXT,
  description     TEXT,
  category        TEXT,
  services        TEXT[] NOT NULL DEFAULT '{}',
  hashtags        TEXT[] NOT NULL DEFAULT '{}'
                    CHECK (cardinality(hashtags) <= 5),
  social_handles  JSONB NOT NULL DEFAULT '{}'::jsonb,
  website         TEXT,
  phone           TEXT,
  email           CITEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_business_profiles_services
  ON public.business_profiles USING GIN(services);
CREATE INDEX IF NOT EXISTS idx_business_profiles_hashtags
  ON public.business_profiles USING GIN(hashtags);
CREATE INDEX IF NOT EXISTS idx_business_profiles_category
  ON public.business_profiles(category);

-- Normalize hashtags on write.
CREATE OR REPLACE FUNCTION public.business_profiles_normalize_hashtags()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.hashtags := public.normalize_hashtags(NEW.hashtags);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_business_profiles_hashtags ON public.business_profiles;
CREATE TRIGGER trg_business_profiles_hashtags
  BEFORE INSERT OR UPDATE ON public.business_profiles
  FOR EACH ROW EXECUTE FUNCTION public.business_profiles_normalize_hashtags();

DROP TRIGGER IF EXISTS trg_business_profiles_updated_at ON public.business_profiles;
CREATE TRIGGER trg_business_profiles_updated_at
  BEFORE UPDATE ON public.business_profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- business_hours
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.business_hours (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_profile_id   UUID NOT NULL REFERENCES public.business_profiles(id) ON DELETE CASCADE,
  day_of_week           INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),  -- 0=Sunday
  open_time             TIME,
  close_time            TIME,
  is_closed             BOOLEAN NOT NULL DEFAULT FALSE,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (business_profile_id, day_of_week)
);

CREATE INDEX IF NOT EXISTS idx_business_hours_bp
  ON public.business_hours(business_profile_id);

-- ---------------------------------------------------------------------------
-- interests (canonical list to power tag pickers)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.interests (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        TEXT UNIQUE NOT NULL,
  name        TEXT NOT NULL,
  category    TEXT,
  icon        TEXT,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_interests_category ON public.interests(category);
