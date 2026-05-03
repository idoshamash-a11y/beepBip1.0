-- Migration 08: posts, conversations, messages
--
-- Social surface (intentionally thin — see MVP_SPEC §3.7):
--   * Businesses can post short updates (time-bounded promos, live updates).
--   * NO personal timelines, NO feeds, NO follow graph in V1.
--   * Posts decay off the neighborhood board after ~72h.
--
-- Messaging:
--   * Direct 1:1 threads between buyer and seller, scoped to a booking.
--   * Listing-level inquiries also create a thread (booking_id NULL).
--   * No group chats, no message reactions, no typing indicators in V1.

-- ---------------------------------------------------------------------------
-- posts
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.posts (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_profile_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  neighborhood_id    UUID NOT NULL REFERENCES public.neighborhoods(id),
  listing_id         UUID REFERENCES public.listings(id) ON DELETE SET NULL,   -- optional link
  content            TEXT NOT NULL CHECK (char_length(content) BETWEEN 1 AND 500),
  images             TEXT[] NOT NULL DEFAULT '{}'
                     CHECK (cardinality(images) <= 4),
  hashtags           TEXT[] NOT NULL DEFAULT '{}'
                     CHECK (cardinality(hashtags) <= 5),
  expires_at         TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '72 hours'),
  is_removed         BOOLEAN NOT NULL DEFAULT FALSE,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_posts_neighborhood_active
  ON public.posts(neighborhood_id, created_at DESC)
  WHERE NOT is_removed;

CREATE INDEX IF NOT EXISTS idx_posts_author
  ON public.posts(author_profile_id);

CREATE INDEX IF NOT EXISTS idx_posts_hashtags
  ON public.posts USING GIN(hashtags);

CREATE INDEX IF NOT EXISTS idx_posts_expires_at
  ON public.posts(expires_at) WHERE NOT is_removed;

CREATE OR REPLACE FUNCTION public.posts_normalize_hashtags()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.hashtags := public.normalize_hashtags(NEW.hashtags);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_posts_hashtags ON public.posts;
CREATE TRIGGER trg_posts_hashtags
  BEFORE INSERT OR UPDATE ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.posts_normalize_hashtags();

DROP TRIGGER IF EXISTS trg_posts_updated_at ON public.posts;
CREATE TRIGGER trg_posts_updated_at
  BEFORE UPDATE ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- conversations
--   1:1 between two profiles, optionally scoped to a listing or booking.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.conversations (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id            UUID REFERENCES public.listings(id) ON DELETE SET NULL,
  booking_id            UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
  participant_a         UUID NOT NULL REFERENCES public.profiles(id),
  participant_b         UUID NOT NULL REFERENCES public.profiles(id),
  last_message_at       TIMESTAMPTZ,
  last_message_preview  TEXT,
  a_unread_count        INTEGER NOT NULL DEFAULT 0,
  b_unread_count        INTEGER NOT NULL DEFAULT 0,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT conv_participants_distinct CHECK (participant_a <> participant_b),
  -- Canonical ordering so the same pair always yields the same row
  CONSTRAINT conv_canonical_order       CHECK (participant_a < participant_b)
);

-- Uniqueness: one conversation per (listing, pair) and per (booking, pair).
-- We use partial unique indexes rather than a single UNIQUE so NULL scope
-- columns don't collide awkwardly.
CREATE UNIQUE INDEX IF NOT EXISTS idx_conv_unique_by_listing
  ON public.conversations(listing_id, participant_a, participant_b)
  WHERE listing_id IS NOT NULL AND booking_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_conv_unique_by_booking
  ON public.conversations(booking_id, participant_a, participant_b)
  WHERE booking_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_conv_a_last ON public.conversations(participant_a, last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_conv_b_last ON public.conversations(participant_b, last_message_at DESC);

DROP TRIGGER IF EXISTS trg_conversations_updated_at ON public.conversations;
CREATE TRIGGER trg_conversations_updated_at
  BEFORE UPDATE ON public.conversations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- messages
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.messages (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id    UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_profile_id  UUID NOT NULL REFERENCES public.profiles(id),
  body               TEXT NOT NULL CHECK (char_length(body) BETWEEN 1 AND 2000),
  attachments        TEXT[] NOT NULL DEFAULT '{}'
                     CHECK (cardinality(attachments) <= 3),
  is_system          BOOLEAN NOT NULL DEFAULT FALSE,   -- booking-status system messages
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  read_at            TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_messages_conv_created
  ON public.messages(conversation_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_messages_sender
  ON public.messages(sender_profile_id);

-- When a message is inserted, bump the conversation's rollup fields so the
-- inbox UI can render without an additional aggregation query per row.
CREATE OR REPLACE FUNCTION public.messages_bump_conversation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_is_a BOOLEAN;
BEGIN
  SELECT (participant_a = NEW.sender_profile_id) INTO v_is_a
  FROM public.conversations
  WHERE id = NEW.conversation_id;

  UPDATE public.conversations
  SET
    last_message_at      = NEW.created_at,
    last_message_preview = left(NEW.body, 120),
    a_unread_count       = CASE WHEN v_is_a THEN a_unread_count ELSE a_unread_count + 1 END,
    b_unread_count       = CASE WHEN v_is_a THEN b_unread_count + 1 ELSE b_unread_count END,
    updated_at           = NOW()
  WHERE id = NEW.conversation_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_messages_bump_conversation ON public.messages;
CREATE TRIGGER trg_messages_bump_conversation
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.messages_bump_conversation();
