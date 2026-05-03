-- Migration 06: bookings, payments, stripe_accounts
--
-- Payment model: Stripe Connect (Standard accounts).
--   * Buyer pays the platform (charge with on_behalf_of = seller account).
--   * Funds sit in the platform balance (escrow) until release:
--       - buyer confirms completion, OR
--       - 72h after `delivered_at` / service end, auto-release fires.
--   * Release = Stripe Transfer to the seller's connected account.
--   * Platform keeps `platform_fee_cents` as revenue.
--
-- Every money movement is recorded as an immutable row in `payments`.
-- Booking state transitions are allowed only in specific directions,
-- enforced by the trg_bookings_validate_transition trigger below.

-- ---------------------------------------------------------------------------
-- stripe_accounts (1:1 with profiles that can receive money)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.stripe_accounts (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id               UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  stripe_account_id        TEXT UNIQUE NOT NULL,
  charges_enabled          BOOLEAN NOT NULL DEFAULT FALSE,
  payouts_enabled          BOOLEAN NOT NULL DEFAULT FALSE,
  details_submitted        BOOLEAN NOT NULL DEFAULT FALSE,
  requirements_currently_due TEXT[],
  country                  TEXT,
  default_currency         TEXT,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stripe_accounts_profile
  ON public.stripe_accounts(profile_id);

DROP TRIGGER IF EXISTS trg_stripe_accounts_updated_at ON public.stripe_accounts;
CREATE TRIGGER trg_stripe_accounts_updated_at
  BEFORE UPDATE ON public.stripe_accounts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- bookings
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.bookings (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id                UUID NOT NULL REFERENCES public.listings(id),
  buyer_profile_id          UUID NOT NULL REFERENCES public.profiles(id),
  seller_profile_id         UUID NOT NULL REFERENCES public.profiles(id),
  neighborhood_id           UUID NOT NULL REFERENCES public.neighborhoods(id),
  status                    public.booking_status NOT NULL DEFAULT 'pending',
  quantity                  INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  unit_price_cents          INTEGER NOT NULL CHECK (unit_price_cents >= 0),
  subtotal_cents            INTEGER NOT NULL CHECK (subtotal_cents >= 0),
  platform_fee_cents        INTEGER NOT NULL DEFAULT 0 CHECK (platform_fee_cents >= 0),
  tax_cents                 INTEGER NOT NULL DEFAULT 0 CHECK (tax_cents >= 0),
  total_cents               INTEGER NOT NULL CHECK (total_cents >= 0),
  currency                  TEXT NOT NULL DEFAULT 'USD',
  scheduled_for             TIMESTAMPTZ,                       -- services & events
  delivered_at              TIMESTAMPTZ,                       -- service performed / item delivered
  auto_release_at           TIMESTAMPTZ,                       -- scheduled escrow release
  completed_at              TIMESTAMPTZ,
  cancelled_at              TIMESTAMPTZ,
  cancellation_reason       TEXT,
  stripe_payment_intent_id  TEXT UNIQUE,
  stripe_charge_id          TEXT UNIQUE,
  idempotency_key           TEXT UNIQUE,
  buyer_note                TEXT,
  seller_note               TEXT,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT bookings_buyer_seller_distinct CHECK (buyer_profile_id <> seller_profile_id),
  CONSTRAINT bookings_totals_consistent     CHECK (total_cents = subtotal_cents + platform_fee_cents + tax_cents)
);

CREATE INDEX IF NOT EXISTS idx_bookings_listing        ON public.bookings(listing_id);
CREATE INDEX IF NOT EXISTS idx_bookings_buyer          ON public.bookings(buyer_profile_id);
CREATE INDEX IF NOT EXISTS idx_bookings_seller         ON public.bookings(seller_profile_id);
CREATE INDEX IF NOT EXISTS idx_bookings_neighborhood   ON public.bookings(neighborhood_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status_created ON public.bookings(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bookings_auto_release
  ON public.bookings(auto_release_at)
  WHERE status = 'paid' AND auto_release_at IS NOT NULL;

DROP TRIGGER IF EXISTS trg_bookings_updated_at ON public.bookings;
CREATE TRIGGER trg_bookings_updated_at
  BEFORE UPDATE ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Enforce legal state transitions. Anything else raises.
CREATE OR REPLACE FUNCTION public.bookings_validate_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  allowed BOOLEAN := FALSE;
BEGIN
  IF TG_OP = 'INSERT' THEN
    RETURN NEW;
  END IF;

  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  allowed := CASE OLD.status
    WHEN 'pending'     THEN NEW.status IN ('accepted', 'cancelled')
    WHEN 'accepted'    THEN NEW.status IN ('paid', 'cancelled')
    WHEN 'paid'        THEN NEW.status IN ('in_progress', 'completed', 'disputed', 'refunded')
    WHEN 'in_progress' THEN NEW.status IN ('completed', 'disputed', 'refunded')
    WHEN 'disputed'    THEN NEW.status IN ('completed', 'refunded')
    ELSE FALSE
  END;

  IF NOT allowed THEN
    RAISE EXCEPTION 'Illegal booking status transition: % -> %', OLD.status, NEW.status;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_bookings_validate_transition ON public.bookings;
CREATE TRIGGER trg_bookings_validate_transition
  BEFORE UPDATE OF status ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.bookings_validate_transition();

-- ---------------------------------------------------------------------------
-- payments (immutable ledger)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.payments (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id            UUID NOT NULL REFERENCES public.bookings(id) ON DELETE RESTRICT,
  movement              public.payment_movement NOT NULL,
  amount_cents          INTEGER NOT NULL,                          -- signed: +charge / -refund
  currency              TEXT NOT NULL DEFAULT 'USD',
  stripe_object_id      TEXT,                                      -- pi_*, tr_*, re_*, ch_*
  stripe_event_id       TEXT,                                      -- webhook idempotency
  description           TEXT,
  metadata              JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (stripe_event_id)
);

CREATE INDEX IF NOT EXISTS idx_payments_booking  ON public.payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_movement ON public.payments(movement);
CREATE INDEX IF NOT EXISTS idx_payments_created  ON public.payments(created_at DESC);
