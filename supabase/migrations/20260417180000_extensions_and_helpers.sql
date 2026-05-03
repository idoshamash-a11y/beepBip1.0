-- Migration 00: extensions & helper functions
--
-- Purpose
--   Enable PostgreSQL extensions required across the rest of the schema and
--   define small helper/utility functions used by multiple downstream
--   migrations. Keeping these in migration 00 means later migrations don't
--   need to worry about load order for these primitives.
--
-- Idempotency: all CREATE statements use IF NOT EXISTS / OR REPLACE so this
-- migration is safe to re-run during local development iteration.

-- ---------------------------------------------------------------------------
-- Extensions
--
-- Notes on schema:
--   Supabase pre-installs `uuid-ossp` and `pgcrypto` in the `extensions`
--   schema (NOT in `public`). The `extensions` schema is on the search_path
--   for normal client sessions but NOT for SECURITY DEFINER functions or
--   trigger contexts unless we explicitly add it. Therefore:
--     * Prefer `gen_random_uuid()` for primary keys -- it lives in
--       `pg_catalog` (built into PG 13+) and needs no qualification.
--     * For anything from pgcrypto/uuid-ossp that doesn't have a core
--       equivalent (e.g. `gen_random_bytes`), schema-qualify the call as
--       `extensions.<func>(...)`.
--   We keep the IF NOT EXISTS lines below so a non-Supabase Postgres still
--   works, but on Supabase they are no-ops because the extensions already
--   exist in the `extensions` schema.
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp"           SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto"            SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "postgis";                   -- geography, geometry, ST_* functions
CREATE EXTENSION IF NOT EXISTS "pg_trgm";                   -- trigram similarity for typo-tolerant search
CREATE EXTENSION IF NOT EXISTS "citext";                    -- case-insensitive text (email, handles)
CREATE EXTENSION IF NOT EXISTS "btree_gin";                 -- enables GIN across multiple column types
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";        -- query performance telemetry

-- ---------------------------------------------------------------------------
-- Generic updated_at trigger (used by every table with an updated_at column)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Hashtag normalization
--   Converts a raw hashtag input (possibly with '#', mixed case, whitespace,
--   punctuation) into a canonical storage form: lowercase, alphanumeric +
--   underscore only, max 40 chars. Used by hashtag search RPC and validation.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.normalize_hashtag(raw TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT left(
    lower(
      regexp_replace(
        trim(leading '#' from coalesce(raw, '')),
        '[^a-z0-9_]',
        '',
        'g'
      )
    ),
    40
  );
$$;

-- ---------------------------------------------------------------------------
-- Hashtag array normalization
--   Applies normalize_hashtag to every element and drops empty / duplicate
--   entries. Use this in BEFORE INSERT/UPDATE triggers on tables that store
--   hashtag arrays to guarantee a canonical representation.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.normalize_hashtags(raw TEXT[])
RETURNS TEXT[]
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT COALESCE(
    array_agg(DISTINCT tag ORDER BY tag)
      FILTER (WHERE tag IS NOT NULL AND length(tag) > 0),
    '{}'::TEXT[]
  )
  FROM unnest(coalesce(raw, '{}'::TEXT[])) AS t(input)
  CROSS JOIN LATERAL (SELECT public.normalize_hashtag(t.input) AS tag) s;
$$;

-- ---------------------------------------------------------------------------
-- Serial ID generator (BP-XXXXXX)
--   Used for human-friendly public user IDs.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_serial_id()
RETURNS TEXT
LANGUAGE plpgsql
-- Fully-qualified extension call below means this function is safe to call
-- from any context (auth triggers, RPC SECURITY DEFINER, postgrest) without
-- relying on `extensions` being on the caller's search_path.
AS $$
DECLARE
  candidate TEXT;
  attempts  INT := 0;
BEGIN
  LOOP
    attempts := attempts + 1;
    candidate := 'BP-' || upper(substring(encode(extensions.gen_random_bytes(6), 'hex') from 1 for 6));
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.users WHERE serial_id = candidate);
    IF attempts > 10 THEN
      RAISE EXCEPTION 'Could not generate unique serial_id after % attempts', attempts;
    END IF;
  END LOOP;
  RETURN candidate;
END;
$$;
