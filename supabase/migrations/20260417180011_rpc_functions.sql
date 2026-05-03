-- Migration 11: RPC (Remote Procedure Call) functions
--
-- The client calls these via PostgREST (supabase.rpc('fn_name', args)).
-- They encapsulate any operation that:
--   * Needs to bypass RLS safely (SECURITY DEFINER).
--   * Involves multiple table writes atomically.
--   * Has pricing / fee / feedback logic that we don't want on the client.
--
-- Every SECURITY DEFINER function pins search_path = public, pg_temp to block
-- search_path hijack attacks, and validates the caller's identity explicitly
-- instead of relying on RLS (since SECURITY DEFINER bypasses it).

-- ---------------------------------------------------------------------------
-- discover_listings
--   Neighborhood-scoped search with optional geo distance, text query,
--   hashtags, type filter, and pagination. Always returns `active` listings
--   authored by `open` profiles.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.discover_listings(
  p_neighborhood_slug TEXT,
  p_lat               DOUBLE PRECISION DEFAULT NULL,
  p_lng               DOUBLE PRECISION DEFAULT NULL,
  p_radius_meters     INTEGER DEFAULT NULL,
  p_query             TEXT DEFAULT NULL,
  p_hashtags          TEXT[] DEFAULT NULL,
  p_type              public.listing_type DEFAULT NULL,
  p_limit             INTEGER DEFAULT 30,
  p_offset            INTEGER DEFAULT 0
)
RETURNS TABLE (
  listing_id         UUID,
  profile_id         UUID,
  title              TEXT,
  price_cents        INTEGER,
  currency           TEXT,
  type               public.listing_type,
  images             TEXT[],
  hashtags           TEXT[],
  distance_meters    DOUBLE PRECISION,
  rank               REAL
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_neighborhood_id UUID;
  v_point           GEOGRAPHY;
  v_tags            TEXT[];
  v_tsquery         TSQUERY;
BEGIN
  SELECT n.id INTO v_neighborhood_id
  FROM public.neighborhoods n
  WHERE n.slug = p_neighborhood_slug AND n.status = 'active';

  IF v_neighborhood_id IS NULL THEN
    RETURN;
  END IF;

  IF p_lat IS NOT NULL AND p_lng IS NOT NULL THEN
    v_point := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography;
  END IF;

  v_tags := public.normalize_hashtags(p_hashtags);

  IF p_query IS NOT NULL AND length(trim(p_query)) > 0 THEN
    v_tsquery := websearch_to_tsquery('english', p_query);
  END IF;

  RETURN QUERY
  SELECT
    l.id          AS listing_id,
    l.profile_id,
    l.title,
    l.price_cents,
    l.currency,
    l.type,
    l.images,
    l.hashtags,
    CASE
      WHEN v_point IS NOT NULL THEN
        ST_Distance(v_point, loc.geog)
      ELSE NULL
    END AS distance_meters,
    CASE
      WHEN v_tsquery IS NOT NULL THEN
        ts_rank_cd(l.search_vector, v_tsquery)
      ELSE 0
    END AS rank
  FROM public.listings l
  JOIN public.profiles p ON p.id = l.profile_id
  LEFT JOIN LATERAL (
    SELECT geog
    FROM public.locations loc
    WHERE loc.profile_id = l.profile_id
    ORDER BY is_primary DESC, created_at
    LIMIT 1
  ) loc ON TRUE
  WHERE l.neighborhood_id = v_neighborhood_id
    AND l.status           = 'active'
    AND p.visibility_status = 'open'
    AND (p_type     IS NULL OR l.type = p_type)
    AND (v_tsquery  IS NULL OR l.search_vector @@ v_tsquery)
    AND (cardinality(v_tags) = 0 OR l.hashtags && v_tags)
    AND (
      v_point IS NULL
      OR p_radius_meters IS NULL
      OR (loc.geog IS NOT NULL AND ST_DWithin(v_point, loc.geog, p_radius_meters))
    )
  ORDER BY
    CASE WHEN v_tsquery IS NOT NULL THEN ts_rank_cd(l.search_vector, v_tsquery) END DESC NULLS LAST,
    CASE WHEN v_point   IS NOT NULL THEN ST_Distance(v_point, loc.geog)         END ASC  NULLS LAST,
    l.created_at DESC
  LIMIT GREATEST(p_limit, 1)
  OFFSET GREATEST(p_offset, 0);
END;
$$;

GRANT EXECUTE ON FUNCTION public.discover_listings(
  TEXT, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, TEXT, TEXT[],
  public.listing_type, INTEGER, INTEGER
) TO authenticated, anon;

-- ---------------------------------------------------------------------------
-- compute_platform_fee
--   Central pricing logic so the server is the source of truth for fees.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.compute_platform_fee(
  p_neighborhood_id UUID,
  p_subtotal_cents  INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_bps       INTEGER;
  v_promo_bps INTEGER;
  v_promo_end TIMESTAMPTZ;
BEGIN
  SELECT platform_fee_bps, promo_fee_bps, promo_ends_at
  INTO v_bps, v_promo_bps, v_promo_end
  FROM public.neighborhoods
  WHERE id = p_neighborhood_id;

  IF v_bps IS NULL THEN
    RAISE EXCEPTION 'Unknown neighborhood %', p_neighborhood_id;
  END IF;

  IF v_promo_bps IS NOT NULL AND (v_promo_end IS NULL OR v_promo_end > NOW()) THEN
    v_bps := v_promo_bps;
  END IF;

  RETURN GREATEST((p_subtotal_cents * v_bps) / 10000, 0);
END;
$$;

GRANT EXECUTE ON FUNCTION public.compute_platform_fee(UUID, INTEGER)
  TO authenticated, service_role;

-- ---------------------------------------------------------------------------
-- create_booking_draft
--   Buyer-initiated: creates a 'pending' booking with computed fees. Does NOT
--   charge — that happens via Stripe webhook once the PaymentIntent confirms.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_booking_draft(
  p_listing_id   UUID,
  p_quantity     INTEGER DEFAULT 1,
  p_scheduled_for TIMESTAMPTZ DEFAULT NULL,
  p_buyer_note    TEXT DEFAULT NULL,
  p_idempotency_key TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_listing         public.listings%ROWTYPE;
  v_buyer_profile_id UUID;
  v_subtotal        INTEGER;
  v_fee             INTEGER;
  v_total           INTEGER;
  v_booking_id      UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'authentication required';
  END IF;

  SELECT id INTO v_buyer_profile_id
  FROM public.profiles
  WHERE user_id = auth.uid() AND profile_type = 'personal'
  LIMIT 1;

  IF v_buyer_profile_id IS NULL THEN
    RAISE EXCEPTION 'buyer profile not found';
  END IF;

  SELECT * INTO v_listing FROM public.listings WHERE id = p_listing_id;
  IF v_listing.id IS NULL OR v_listing.status <> 'active' THEN
    RAISE EXCEPTION 'listing not available';
  END IF;

  IF v_listing.profile_id = v_buyer_profile_id THEN
    RAISE EXCEPTION 'cannot book your own listing';
  END IF;

  IF p_idempotency_key IS NOT NULL THEN
    SELECT id INTO v_booking_id
    FROM public.bookings
    WHERE idempotency_key = p_idempotency_key AND buyer_profile_id = v_buyer_profile_id;
    IF v_booking_id IS NOT NULL THEN
      RETURN v_booking_id;
    END IF;
  END IF;

  v_subtotal := v_listing.price_cents * GREATEST(p_quantity, 1);
  v_fee      := public.compute_platform_fee(v_listing.neighborhood_id, v_subtotal);
  v_total    := v_subtotal + v_fee;

  INSERT INTO public.bookings (
    listing_id, buyer_profile_id, seller_profile_id, neighborhood_id,
    status, quantity, unit_price_cents, subtotal_cents, platform_fee_cents,
    tax_cents, total_cents, currency, scheduled_for, buyer_note, idempotency_key
  ) VALUES (
    v_listing.id, v_buyer_profile_id, v_listing.profile_id, v_listing.neighborhood_id,
    'pending', p_quantity, v_listing.price_cents, v_subtotal, v_fee,
    0, v_total, v_listing.currency, p_scheduled_for, p_buyer_note, p_idempotency_key
  ) RETURNING id INTO v_booking_id;

  RETURN v_booking_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_booking_draft(
  UUID, INTEGER, TIMESTAMPTZ, TEXT, TEXT
) TO authenticated;

-- ---------------------------------------------------------------------------
-- release_expired_escrows
--   Intended to run on a schedule (pg_cron or an edge-function cron).
--   Marks paid bookings past their auto_release_at as completed, which is the
--   signal for the payouts worker to issue Stripe Transfers.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.release_expired_escrows()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  WITH updated AS (
    UPDATE public.bookings
    SET status = 'completed', completed_at = NOW()
    WHERE status = 'paid'
      AND auto_release_at IS NOT NULL
      AND auto_release_at <= NOW()
      AND NOT EXISTS (
        SELECT 1 FROM public.disputes d WHERE d.booking_id = bookings.id AND d.status = 'open'
      )
    RETURNING id
  )
  SELECT count(*) INTO v_count FROM updated;
  RETURN COALESCE(v_count, 0);
END;
$$;

REVOKE ALL ON FUNCTION public.release_expired_escrows() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.release_expired_escrows() TO service_role;

-- ---------------------------------------------------------------------------
-- publish_ripe_feedback
--   Implements the double-blind rule: publish both sides' feedback once both
--   are present, OR when 7d have elapsed since booking completion.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.publish_ripe_feedback()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_count INTEGER := 0;
BEGIN
  WITH both_submitted AS (
    SELECT f.booking_id
    FROM public.feedback f
    WHERE NOT f.is_published
    GROUP BY f.booking_id
    HAVING count(DISTINCT f.author_profile_id) >= 2
  ),
  window_closed AS (
    SELECT f.booking_id
    FROM public.feedback f
    JOIN public.bookings b ON b.id = f.booking_id
    WHERE NOT f.is_published
      AND b.completed_at IS NOT NULL
      AND b.completed_at <= NOW() - INTERVAL '7 days'
  ),
  to_publish AS (
    SELECT booking_id FROM both_submitted
    UNION
    SELECT booking_id FROM window_closed
  ),
  updated AS (
    UPDATE public.feedback f
    SET is_published = TRUE, published_at = NOW()
    FROM to_publish tp
    WHERE f.booking_id = tp.booking_id AND NOT f.is_published
    RETURNING f.id
  )
  SELECT count(*) INTO v_count FROM updated;
  RETURN COALESCE(v_count, 0);
END;
$$;

REVOKE ALL ON FUNCTION public.publish_ripe_feedback() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.publish_ripe_feedback() TO service_role;

-- ---------------------------------------------------------------------------
-- submit_feedback
--   Buyer or seller writes their side of feedback. Stays unpublished until
--   publish_ripe_feedback flips it (double-blind).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_feedback(
  p_booking_id UUID,
  p_tone       public.feedback_tone,
  p_tags       TEXT[] DEFAULT '{}',
  p_comment    TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_booking      public.bookings%ROWTYPE;
  v_author_id    UUID;
  v_subject_id   UUID;
  v_feedback_id  UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'authentication required';
  END IF;

  SELECT * INTO v_booking FROM public.bookings WHERE id = p_booking_id;
  IF v_booking.id IS NULL THEN
    RAISE EXCEPTION 'booking not found';
  END IF;

  IF v_booking.status NOT IN ('completed', 'in_progress', 'disputed') THEN
    RAISE EXCEPTION 'feedback only allowed after service begins';
  END IF;

  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = v_booking.buyer_profile_id AND user_id = auth.uid()) THEN
    v_author_id  := v_booking.buyer_profile_id;
    v_subject_id := v_booking.seller_profile_id;
  ELSIF EXISTS (SELECT 1 FROM public.profiles WHERE id = v_booking.seller_profile_id AND user_id = auth.uid()) THEN
    v_author_id  := v_booking.seller_profile_id;
    v_subject_id := v_booking.buyer_profile_id;
  ELSE
    RAISE EXCEPTION 'not a party to this booking';
  END IF;

  INSERT INTO public.feedback (
    booking_id, author_profile_id, subject_profile_id, tone, tags, comment
  ) VALUES (
    p_booking_id, v_author_id, v_subject_id, p_tone,
    COALESCE(p_tags, '{}'), p_comment
  )
  ON CONFLICT (booking_id, author_profile_id) DO UPDATE
    SET tone    = EXCLUDED.tone,
        tags    = EXCLUDED.tags,
        comment = EXCLUDED.comment,
        updated_at = NOW()
  RETURNING id INTO v_feedback_id;

  -- Opportunistically publish if both sides are now in.
  PERFORM public.publish_ripe_feedback();

  RETURN v_feedback_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.submit_feedback(
  UUID, public.feedback_tone, TEXT[], TEXT
) TO authenticated;

-- ---------------------------------------------------------------------------
-- expire_old_posts
--   Soft-removes posts past expires_at so they drop out of the neighborhood
--   feed. Run from the same cron that triggers escrow / feedback jobs.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.expire_old_posts()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  WITH updated AS (
    UPDATE public.posts
    SET is_removed = TRUE
    WHERE NOT is_removed AND expires_at <= NOW()
    RETURNING id
  )
  SELECT count(*) INTO v_count FROM updated;
  RETURN COALESCE(v_count, 0);
END;
$$;

REVOKE ALL ON FUNCTION public.expire_old_posts() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.expire_old_posts() TO service_role;
