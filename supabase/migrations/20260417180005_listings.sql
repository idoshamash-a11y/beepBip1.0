-- Migration 05: listings
--
-- A listing is the atomic unit of commerce: a service to book, an item to
-- buy, or an event to attend. Listings are always scoped to one neighborhood
-- so discovery queries stay bounded.
--
-- Search strategy:
--   * Full-text via tsvector on (title + description) — for natural language.
--   * GIN on hashtags array — for tag filtering.
--   * GIN trigram on title — for typo tolerance.
--   * B-tree composite on (neighborhood_id, status, created_at) — for feeds.

CREATE TABLE IF NOT EXISTS public.listings (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  neighborhood_id    UUID NOT NULL REFERENCES public.neighborhoods(id),
  type               public.listing_type NOT NULL,
  title              TEXT NOT NULL CHECK (char_length(title) BETWEEN 2 AND 120),
  description        TEXT CHECK (description IS NULL OR char_length(description) <= 4000),
  price_cents        INTEGER NOT NULL CHECK (price_cents >= 0),
  currency           TEXT NOT NULL DEFAULT 'USD',
  duration_minutes   INTEGER CHECK (duration_minutes IS NULL OR duration_minutes > 0),   -- services
  capacity           INTEGER CHECK (capacity IS NULL OR capacity > 0),                    -- events
  stock              INTEGER CHECK (stock IS NULL OR stock >= 0),                         -- items
  images             TEXT[] NOT NULL DEFAULT '{}'
                     CHECK (cardinality(images) <= 10),
  hashtags           TEXT[] NOT NULL DEFAULT '{}'
                     CHECK (cardinality(hashtags) <= 10),
  status             public.listing_status NOT NULL DEFAULT 'draft',
  starts_at          TIMESTAMPTZ,
  ends_at            TIMESTAMPTZ,
  search_vector      tsvector
                     GENERATED ALWAYS AS
                     (
                       setweight(to_tsvector('english', coalesce(title, '')),       'A') ||
                       setweight(to_tsvector('english', coalesce(description, '')), 'B')
                     ) STORED,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT listings_event_dates_chk
    CHECK (type <> 'event' OR (starts_at IS NOT NULL AND ends_at >= starts_at))
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_listings_neighborhood_status_created
  ON public.listings(neighborhood_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_listings_profile
  ON public.listings(profile_id);

CREATE INDEX IF NOT EXISTS idx_listings_search
  ON public.listings USING GIN(search_vector);

CREATE INDEX IF NOT EXISTS idx_listings_hashtags
  ON public.listings USING GIN(hashtags);

CREATE INDEX IF NOT EXISTS idx_listings_title_trgm
  ON public.listings USING GIN(title gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_listings_type
  ON public.listings(type) WHERE status = 'active';

-- Hashtag normalization trigger (same pattern as business_profiles).
CREATE OR REPLACE FUNCTION public.listings_normalize_hashtags()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.hashtags := public.normalize_hashtags(NEW.hashtags);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_listings_hashtags ON public.listings;
CREATE TRIGGER trg_listings_hashtags
  BEFORE INSERT OR UPDATE ON public.listings
  FOR EACH ROW EXECUTE FUNCTION public.listings_normalize_hashtags();

DROP TRIGGER IF EXISTS trg_listings_updated_at ON public.listings;
CREATE TRIGGER trg_listings_updated_at
  BEFORE UPDATE ON public.listings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
