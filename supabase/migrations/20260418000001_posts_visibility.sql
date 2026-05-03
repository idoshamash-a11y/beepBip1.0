-- Migration 13: per-post visibility (public vs unlisted).
--
-- Why this exists:
--   The original `posts` schema in migration 08 treated every post as a
--   neighborhood broadcast — visible to anyone in SoHo for 72 hours, gated
--   only by `is_removed` and `expires_at`. Product feedback (founder, 2026-04-28)
--   asked for a Public/Unlisted toggle so authors can publish a post that
--   doesn't appear in feed / map / search but is still reachable by direct
--   link (e.g. share to a small group via copy-paste, or pre-stage a post
--   to QA without spamming the neighborhood board).
--
-- Design choices:
--   * `unlisted` (not `private`) because the row is technically reachable
--     by anyone with the id; "private" implies a friend graph we don't have.
--   * Author still sees their own unlisted posts everywhere — no lock-out.
--   * Default = `public` so existing surfaces keep behaving as before.
--   * Visibility is *separate* from `is_removed` (soft delete) and the
--     future `moderation_status` (FOLLOWUPS §1.7). They compose.
--
-- Forward-only and idempotent: safe to re-run.

-- ---------------------------------------------------------------------------
-- 1. Add the column with a check constraint.
-- ---------------------------------------------------------------------------
ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS visibility TEXT NOT NULL DEFAULT 'public'
  CHECK (visibility IN ('public', 'unlisted'));

-- ---------------------------------------------------------------------------
-- 2. Discovery index — supports the neighborhood-feed query path.
--    The original idx_posts_neighborhood_active in migration 08 ignored
--    visibility; we add a tighter one here so the most common select
--    (feed + map) hits a partial index.
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_posts_neighborhood_public
  ON public.posts(neighborhood_id, created_at DESC)
  WHERE visibility = 'public' AND NOT is_removed;

-- ---------------------------------------------------------------------------
-- 3. Replace the existing select policy so unlisted posts are hidden from
--    non-owners. Owners keep full read on their own rows regardless of
--    state (matches the analogous listings_select_active behaviour).
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS posts_select_active ON public.posts;

CREATE POLICY posts_select_active ON public.posts
  FOR SELECT USING (
    -- Author always sees their own rows in any state.
    public.owns_profile(author_profile_id)
    OR (
      visibility = 'public'
      AND NOT is_removed
      AND expires_at > NOW()
    )
  );
