-- Migration 04: locations
--
-- One profile can have multiple locations (e.g., a business with two
-- storefronts). We store PostGIS geography points for precise distance
-- queries and auto-resolve the containing neighborhood on write.

CREATE TABLE IF NOT EXISTS public.locations (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  neighborhood_id     UUID REFERENCES public.neighborhoods(id),    -- may be NULL if outside all polygons
  latitude            DOUBLE PRECISION NOT NULL CHECK (latitude  BETWEEN  -90 AND  90),
  longitude           DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  geog                GEOGRAPHY(POINT, 4326)
                      GENERATED ALWAYS AS
                      (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography) STORED,
  address_line_1      TEXT,
  address_line_2      TEXT,
  city                TEXT,
  state               TEXT,
  country             TEXT,
  postal_code         TEXT,
  is_primary          BOOLEAN NOT NULL DEFAULT FALSE,
  location_name       TEXT,                                  -- label for businesses w/ multiple sites
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Only one primary location per profile.
CREATE UNIQUE INDEX IF NOT EXISTS idx_locations_one_primary_per_profile
  ON public.locations(profile_id) WHERE is_primary;

CREATE INDEX IF NOT EXISTS idx_locations_geog
  ON public.locations USING GIST(geog);

CREATE INDEX IF NOT EXISTS idx_locations_profile
  ON public.locations(profile_id);

CREATE INDEX IF NOT EXISTS idx_locations_neighborhood
  ON public.locations(neighborhood_id);

-- Auto-resolve neighborhood_id from lat/lng on insert/update if not set.
CREATE OR REPLACE FUNCTION public.locations_resolve_neighborhood()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.neighborhood_id IS NULL THEN
    NEW.neighborhood_id := public.neighborhood_for_point(NEW.latitude, NEW.longitude);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_locations_resolve_neighborhood ON public.locations;
CREATE TRIGGER trg_locations_resolve_neighborhood
  BEFORE INSERT OR UPDATE OF latitude, longitude ON public.locations
  FOR EACH ROW EXECUTE FUNCTION public.locations_resolve_neighborhood();

DROP TRIGGER IF EXISTS trg_locations_updated_at ON public.locations;
CREATE TRIGGER trg_locations_updated_at
  BEFORE UPDATE ON public.locations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
