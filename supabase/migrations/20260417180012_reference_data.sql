-- ===========================================================================
-- Migration 12: reference data (neighborhoods, interests, banned hashtags,
--               feature flag definitions).
--
-- Why this is a migration and not just `seed.sql`:
--   - `seed.sql` is local-dev only; it is NEVER applied to a remote project.
--   - This data is required to exist in EVERY environment (dev, staging,
--     prod) before the app can function:
--       * neighborhoods.soho-nyc       -> scopes all discovery / fee logic
--       * interests.*                  -> personal profile picker
--       * banned_hashtags.*            -> moderation safety net (RLS-checked)
--       * feature_flags.*              -> behaviour toggles read by the app
--   - Promoting it to a migration means a single `supabase db push` keeps
--     every environment in sync, with diffs visible in git.
--
-- All inserts are idempotent (ON CONFLICT DO UPDATE) so re-running this is
-- safe and even useful when we tweak the polygon or add new interests.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Neighborhood: SoHo (Manhattan, NYC)
-- Polygon approximates the commonly-accepted SoHo boundaries:
--   N: Houston St | S: Canal St | E: Lafayette/Crosby St | W: 6th Ave
-- Coordinates are (longitude latitude) in WGS84. Tighten later with the
-- official NYC DCP neighborhood geometry.
-- ---------------------------------------------------------------------------
INSERT INTO public.neighborhoods (
  slug, display_name, city, region, country, timezone, currency,
  platform_fee_bps, promo_fee_bps, promo_ends_at, polygon, status, launched_at
) VALUES (
  'soho-nyc',
  'SoHo',
  'New York',
  'NY',
  'US',
  'America/New_York',
  'USD',
  800,          -- 8.00% standard
  0,            -- promo: 0% for launch
  NOW() + INTERVAL '90 days',
  ST_GeogFromText(
    'SRID=4326;POLYGON((' ||
      '-74.0013 40.7282, ' ||     -- NW: Houston @ 6th Ave
      '-73.9961 40.7257, ' ||     -- NE: Houston @ Crosby
      '-73.9994 40.7194, ' ||     -- SE: Canal @ Crosby
      '-74.0045 40.7217, ' ||     -- SW: Canal @ 6th Ave
      '-74.0013 40.7282' ||       -- close
    '))'
  ),
  'active',
  NOW()
)
ON CONFLICT (slug) DO UPDATE
  SET polygon           = EXCLUDED.polygon,
      platform_fee_bps  = EXCLUDED.platform_fee_bps,
      promo_fee_bps     = EXCLUDED.promo_fee_bps,
      promo_ends_at     = EXCLUDED.promo_ends_at,
      status            = EXCLUDED.status,
      updated_at        = NOW();

-- ---------------------------------------------------------------------------
-- Canonical interest tags (for personal profile picker)
-- ---------------------------------------------------------------------------
INSERT INTO public.interests (slug, name, category, sort_order) VALUES
  ('food',         'Food & Drink',   'lifestyle', 10),
  ('fitness',      'Fitness',        'wellness',  20),
  ('wellness',     'Wellness',       'wellness',  30),
  ('art',          'Art',            'culture',   40),
  ('music',        'Music',          'culture',   50),
  ('fashion',      'Fashion',        'style',     60),
  ('beauty',       'Beauty',         'style',     70),
  ('nightlife',    'Nightlife',      'social',    80),
  ('coffee',       'Coffee',         'lifestyle', 90),
  ('wine',         'Wine',           'lifestyle', 100),
  ('pets',         'Pets',           'lifestyle', 110),
  ('kids',         'Kids & Family',  'lifestyle', 120),
  ('outdoors',     'Outdoors',       'lifestyle', 130),
  ('tech',         'Tech',           'interest',  140),
  ('business',     'Business',       'interest',  150),
  ('dating',       'Dating',         'social',    160)
ON CONFLICT (slug) DO UPDATE
  SET name       = EXCLUDED.name,
      category   = EXCLUDED.category,
      sort_order = EXCLUDED.sort_order;

-- ---------------------------------------------------------------------------
-- Banned hashtags — starter seed. Final list to be reviewed with counsel (D11).
-- Normalization happens via CHECK(tag = normalize_hashtag(tag)), so all tags
-- here must already be in canonical form (lowercase, alphanumeric + underscore).
-- ---------------------------------------------------------------------------
INSERT INTO public.banned_hashtags (tag, severity, reason) VALUES
  ('nsfw',            'block',  'adult content not permitted'),
  ('porn',            'block',  'adult content not permitted'),
  ('escort',          'block',  'adult services not permitted'),
  ('drugs',           'block',  'controlled substances not permitted'),
  ('weed',            'review', 'cannabis — requires local legality review'),
  ('gun',             'block',  'firearms not permitted'),
  ('weapons',         'block',  'weapons not permitted'),
  ('gambling',        'block',  'gambling services not permitted'),
  ('crypto',          'review', 'crypto promotions — manual review'),
  ('giveaway',        'review', 'giveaways require clear terms'),
  ('followback',      'hide',   'engagement-bait; keeps discovery signal clean'),
  ('follow4follow',   'hide',   'engagement-bait; keeps discovery signal clean'),
  ('l4l',             'hide',   'engagement-bait; keeps discovery signal clean')
ON CONFLICT (tag) DO UPDATE
  SET severity = EXCLUDED.severity,
      reason   = EXCLUDED.reason;

-- ---------------------------------------------------------------------------
-- Feature flags (default-off; flip via admin panel or service-role update)
-- ---------------------------------------------------------------------------
INSERT INTO public.feature_flags (key, description, enabled, rollout_bps) VALUES
  ('payments.stripe_live',          'Production Stripe Connect path',     FALSE, 0),
  ('onboarding.social_login_tiktok','TikTok Login (V1.5 target)',         FALSE, 0),
  ('onboarding.social_login_ig_biz','Instagram Business Login (V1.5)',    FALSE, 0),
  ('discovery.hashtag_filter',      'Enable hashtag chips in discovery',  TRUE,  10000),
  ('discovery.radius_filter',       'Allow radius filter beyond polygon', FALSE, 0),
  ('messaging.realtime',            'Supabase Realtime for chat (vs poll)', TRUE, 10000),
  ('moderation.auto_hide_reported', 'Auto-hide after 3 reports',          FALSE, 0)
ON CONFLICT (key) DO UPDATE
  SET description = EXCLUDED.description;
