-- Migration 01: custom enum types
--
-- All enums referenced by subsequent migrations live here so individual
-- feature migrations can focus on tables + indexes without worrying about
-- type-creation ordering. Add new enum values with ALTER TYPE in a later
-- dated migration (never edit this file once it has been applied to prod).

-- ---------------------------------------------------------------------------
-- Identity & profiles
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE public.profile_type AS ENUM ('personal', 'business');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.subscription_tier AS ENUM ('free', 'business_pro');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.visibility_status AS ENUM ('open', 'closed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.location_sharing AS ENUM (
    'dont_share',
    'visible_without_location',
    'visible_with_location'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ---------------------------------------------------------------------------
-- Marketplace supply
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE public.listing_type AS ENUM ('service', 'item', 'event');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.listing_status AS ENUM (
    'draft',
    'active',
    'paused',
    'sold_out',
    'removed'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ---------------------------------------------------------------------------
-- Transactions
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE public.booking_status AS ENUM (
    'pending',        -- created, awaiting seller accept (for services)
    'accepted',       -- seller accepted, awaiting buyer pay
    'paid',           -- escrow funded (funds at the platform, not released)
    'in_progress',    -- service in progress / item shipped
    'completed',      -- buyer confirmed OR 72h auto-release fired
    'disputed',       -- buyer raised dispute; escrow locked pending admin
    'cancelled',      -- cancelled before payment captured
    'refunded'        -- money returned to buyer
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.payment_movement AS ENUM (
    'charge',         -- buyer → platform
    'refund',         -- platform → buyer
    'payout',         -- platform → seller
    'fee',            -- platform-retained fee ledger entry
    'adjustment'      -- manual admin correction
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ---------------------------------------------------------------------------
-- Trust layer
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE public.feedback_tone AS ENUM ('positive', 'neutral', 'negative');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.verification_type AS ENUM ('id', 'business_license', 'address');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
