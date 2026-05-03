-- Migration 09: moderation
--
-- Tables supporting Trust & Safety and the admin panel:
--   * verifications        — ID / business license / address verification submissions
--   * reports              — user-submitted complaints about content or actors
--   * banned_hashtags      — global deny-list with severity tiers
--   * muted_hashtags       — per-user soft mutes
--   * feature_flags        — backend-controlled toggles for incremental rollout
--   * admin_audit_log      — minimal record of admin actions for accountability

-- ---------------------------------------------------------------------------
-- verifications
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.verifications (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type              public.verification_type NOT NULL,
  status            TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
  document_urls     TEXT[] NOT NULL DEFAULT '{}',
  stripe_verification_session_id TEXT,
  notes             TEXT,
  reviewed_by       UUID REFERENCES public.users(id),
  reviewed_at       TIMESTAMPTZ,
  expires_at        TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_verifications_profile ON public.verifications(profile_id);
CREATE INDEX IF NOT EXISTS idx_verifications_status  ON public.verifications(status);

DROP TRIGGER IF EXISTS trg_verifications_updated_at ON public.verifications;
CREATE TRIGGER trg_verifications_updated_at
  BEFORE UPDATE ON public.verifications
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- reports
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reports (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_profile_id UUID NOT NULL REFERENCES public.profiles(id),
  target_type        TEXT NOT NULL
                     CHECK (target_type IN ('profile', 'listing', 'post', 'message', 'booking')),
  target_id          UUID NOT NULL,
  reason             TEXT NOT NULL,
  description        TEXT,
  status             TEXT NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending', 'reviewing', 'actioned', 'dismissed')),
  action_taken       TEXT,
  reviewed_by        UUID REFERENCES public.users(id),
  reviewed_at        TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reports_status             ON public.reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_target             ON public.reports(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_reports_reporter           ON public.reports(reporter_profile_id);

DROP TRIGGER IF EXISTS trg_reports_updated_at ON public.reports;
CREATE TRIGGER trg_reports_updated_at
  BEFORE UPDATE ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- banned_hashtags
--   Severity tiers:
--     'block'  — disallow at write time; trigger rejects the INSERT
--     'hide'   — stored, but filtered from discovery surfaces
--     'review' — flag for manual admin review before publication
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.banned_hashtags (
  tag         TEXT PRIMARY KEY
              CHECK (tag = public.normalize_hashtag(tag) AND length(tag) > 0),
  severity    TEXT NOT NULL DEFAULT 'block'
              CHECK (severity IN ('block', 'hide', 'review')),
  reason      TEXT,
  created_by  UUID REFERENCES public.users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- muted_hashtags (per-user soft mute)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.muted_hashtags (
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  tag         TEXT NOT NULL
              CHECK (tag = public.normalize_hashtag(tag) AND length(tag) > 0),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, tag)
);

-- ---------------------------------------------------------------------------
-- feature_flags
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.feature_flags (
  key          TEXT PRIMARY KEY,
  description  TEXT,
  enabled      BOOLEAN NOT NULL DEFAULT FALSE,
  rollout_bps  INTEGER NOT NULL DEFAULT 0 CHECK (rollout_bps BETWEEN 0 AND 10000),
  payload      JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by   UUID REFERENCES public.users(id)
);

DROP TRIGGER IF EXISTS trg_feature_flags_updated_at ON public.feature_flags;
CREATE TRIGGER trg_feature_flags_updated_at
  BEFORE UPDATE ON public.feature_flags
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- admin_audit_log
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_audit_log (
  id            BIGSERIAL PRIMARY KEY,
  actor_id      UUID REFERENCES public.users(id),
  action        TEXT NOT NULL,
  target_type   TEXT,
  target_id     UUID,
  payload       JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_log_actor ON public.admin_audit_log(actor_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_target ON public.admin_audit_log(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_created ON public.admin_audit_log(created_at DESC);

-- Admin role helper (set `is_admin` claim in auth.users raw_app_meta_data).
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    (auth.jwt() -> 'app_metadata' ->> 'is_admin')::boolean,
    FALSE
  );
$$;

-- Reject INSERT/UPDATE of any hashtag array containing a 'block'-severity
-- banned tag. Applied via triggers on the hashtag-bearing tables.
CREATE OR REPLACE FUNCTION public.enforce_banned_hashtags()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_offender TEXT;
BEGIN
  SELECT bh.tag INTO v_offender
  FROM public.banned_hashtags bh
  WHERE bh.severity = 'block'
    AND bh.tag = ANY(NEW.hashtags)
  LIMIT 1;

  IF v_offender IS NOT NULL THEN
    RAISE EXCEPTION 'Hashtag "%" is not allowed', v_offender
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_listings_banned_hashtags ON public.listings;
CREATE TRIGGER trg_listings_banned_hashtags
  BEFORE INSERT OR UPDATE OF hashtags ON public.listings
  FOR EACH ROW EXECUTE FUNCTION public.enforce_banned_hashtags();

DROP TRIGGER IF EXISTS trg_posts_banned_hashtags ON public.posts;
CREATE TRIGGER trg_posts_banned_hashtags
  BEFORE INSERT OR UPDATE OF hashtags ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.enforce_banned_hashtags();

DROP TRIGGER IF EXISTS trg_business_profiles_banned_hashtags ON public.business_profiles;
CREATE TRIGGER trg_business_profiles_banned_hashtags
  BEFORE INSERT OR UPDATE OF hashtags ON public.business_profiles
  FOR EACH ROW EXECUTE FUNCTION public.enforce_banned_hashtags();
