-- Migration 07: feedback, disputes
--
-- Feedback design (see MVP_SPEC §3.6):
--   * No 5-star ratings. Instead: tone (positive / neutral / negative) + tags.
--   * Both sides submit independently within 7d post-completion.
--   * Publication is DOUBLE-BLIND: nothing is visible until both sides submit
--     OR the 7d window closes (whichever comes first). Enforced at read time
--     in the feedback view (see migration 11) via `visible_at` calculation.
--
-- Disputes are lightweight in V1 — a single thread with an admin decision.
-- No automated arbitration, no evidence upload UI (admins can ask over email).

-- ---------------------------------------------------------------------------
-- feedback
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.feedback (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id          UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  author_profile_id   UUID NOT NULL REFERENCES public.profiles(id),
  subject_profile_id  UUID NOT NULL REFERENCES public.profiles(id),   -- who the feedback is about
  tone                public.feedback_tone NOT NULL,
  tags                TEXT[] NOT NULL DEFAULT '{}'
                      CHECK (cardinality(tags) <= 8),
  comment             TEXT CHECK (comment IS NULL OR char_length(comment) <= 500),
  is_published        BOOLEAN NOT NULL DEFAULT FALSE,
  published_at        TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT feedback_author_subject_distinct CHECK (author_profile_id <> subject_profile_id),
  CONSTRAINT feedback_one_per_direction UNIQUE (booking_id, author_profile_id)
);

CREATE INDEX IF NOT EXISTS idx_feedback_booking  ON public.feedback(booking_id);
CREATE INDEX IF NOT EXISTS idx_feedback_subject  ON public.feedback(subject_profile_id) WHERE is_published;
CREATE INDEX IF NOT EXISTS idx_feedback_author   ON public.feedback(author_profile_id);
CREATE INDEX IF NOT EXISTS idx_feedback_tone     ON public.feedback(tone) WHERE is_published;

DROP TRIGGER IF EXISTS trg_feedback_updated_at ON public.feedback;
CREATE TRIGGER trg_feedback_updated_at
  BEFORE UPDATE ON public.feedback
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- disputes
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.disputes (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id         UUID NOT NULL UNIQUE REFERENCES public.bookings(id),
  opened_by          UUID NOT NULL REFERENCES public.profiles(id),
  reason             TEXT NOT NULL,
  description        TEXT,
  status             TEXT NOT NULL DEFAULT 'open'
                     CHECK (status IN ('open', 'investigating', 'resolved_buyer', 'resolved_seller', 'resolved_split', 'closed')),
  resolution_notes   TEXT,
  resolved_by        UUID REFERENCES public.users(id),
  resolved_at        TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_disputes_status ON public.disputes(status);
CREATE INDEX IF NOT EXISTS idx_disputes_booking ON public.disputes(booking_id);

DROP TRIGGER IF EXISTS trg_disputes_updated_at ON public.disputes;
CREATE TRIGGER trg_disputes_updated_at
  BEFORE UPDATE ON public.disputes
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
