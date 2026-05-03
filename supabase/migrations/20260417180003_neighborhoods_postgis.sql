-- Migration 03: neighborhoods (PostGIS)
--
-- Neighborhoods are the primary geographic scoping unit. Every listing,
-- booking, and post is attached to a neighborhood. Expansion beyond SoHo is
-- strictly a matter of inserting a new row here and flipping status = 'active'.
--
-- We use GEOGRAPHY (not GEOMETRY) because:
--   1. Distance queries must be in meters (GEOGRAPHY handles WGS84 natively).
--   2. Containment queries (ST_Covers, ST_Intersects) work identically.
--   3. We never need to do cartesian geometry ops on these polygons.

CREATE TABLE IF NOT EXISTS public.neighborhoods (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug             TEXT UNIQUE NOT NULL,        -- 'soho-nyc'
  display_name     TEXT NOT NULL,               -- 'SoHo'
  city             TEXT NOT NULL,               -- 'New York'
  region           TEXT NOT NULL,               -- 'NY'
  country          TEXT NOT NULL DEFAULT 'US',
  timezone         TEXT NOT NULL DEFAULT 'America/New_York',
  currency         TEXT NOT NULL DEFAULT 'USD',
  platform_fee_bps INTEGER NOT NULL DEFAULT 800       -- 8.00%
                   CHECK (platform_fee_bps BETWEEN 0 AND 3000),
  promo_fee_bps    INTEGER                             -- e.g. 0 for first-90-days promo
                   CHECK (promo_fee_bps IS NULL OR promo_fee_bps BETWEEN 0 AND 3000),
  promo_ends_at    TIMESTAMPTZ,
  polygon          GEOGRAPHY(POLYGON, 4326) NOT NULL,
  centroid         GEOGRAPHY(POINT, 4326)
                   GENERATED ALWAYS AS (ST_Centroid(polygon::geometry)::geography) STORED,
  status           TEXT NOT NULL DEFAULT 'coming_soon'
                   CHECK (status IN ('coming_soon', 'active', 'paused')),
  launched_at      TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Spatial index for polygon containment / proximity queries.
CREATE INDEX IF NOT EXISTS idx_neighborhoods_polygon
  ON public.neighborhoods USING GIST(polygon);

CREATE INDEX IF NOT EXISTS idx_neighborhoods_centroid
  ON public.neighborhoods USING GIST(centroid);

CREATE INDEX IF NOT EXISTS idx_neighborhoods_status
  ON public.neighborhoods(status);

DROP TRIGGER IF EXISTS trg_neighborhoods_updated_at ON public.neighborhoods;
CREATE TRIGGER trg_neighborhoods_updated_at
  BEFORE UPDATE ON public.neighborhoods
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Convenience: given lat/lng, resolve which active neighborhood contains it.
-- Returns NULL if the point is outside all active neighborhoods.
CREATE OR REPLACE FUNCTION public.neighborhood_for_point(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION
)
RETURNS UUID
LANGUAGE sql
STABLE
AS $$
  SELECT n.id
  FROM public.neighborhoods n
  WHERE n.status = 'active'
    AND ST_Covers(n.polygon, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography)
  ORDER BY ST_Distance(n.centroid, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography)
  LIMIT 1;
$$;
