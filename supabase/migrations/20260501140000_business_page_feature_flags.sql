-- Migration 15: Business Page MVP — feature flags only.
--
-- Why no schema changes here:
--   * The `business-media` storage bucket already lives at
--     20260501120000_storage_user_uploads.sql (`user-uploads`, public read,
--     auth.uid()-scoped writes) — the business-page uploads (logo, cover,
--     listing images) reuse it under path prefixes like
--       <auth.uid()>/listings/<uuid>.jpg
--       <auth.uid()>/business/logo/<uuid>.jpg
--       <auth.uid()>/business/cover/<uuid>.jpg
--   * `business_profiles.cover_url`, `hashtags`, `social_handles` already
--     exist on the table — the Dart model just hadn't caught up yet.
--   * `bookings`, `payments`, `stripe_accounts` and the booking state
--     transition trigger already exist in 20260417180006.
--
-- This migration only registers the feature flag the client checks before
-- showing the booking CTA, so we can ship the page without payments wired
-- end-to-end and flip it on once Stripe Connect is fully set up.
--
-- Idempotent: safe to re-run.

INSERT INTO public.feature_flags (key, description, enabled, rollout_bps) VALUES
  ('bookings.enabled', 'Show Book/Reserve/Buy CTA on listing detail and business page', FALSE, 0),
  ('bookings.demo_mode', 'Short-circuit Stripe calls with a mock dialog (dev/staging only). When ON, the CTA opens a fake checkout sheet instead of hitting create-booking-checkout.', TRUE, 10000)
ON CONFLICT (key) DO UPDATE
  SET description = EXCLUDED.description;
