-- Migration 14: storage bucket for user-uploaded images.
--
-- Why this exists:
--   Listings, posts, and profile photos all need a place to store user
--   pictures. We create a single public-read bucket `user-uploads` so any
--   client can render images via a stable public URL (no signed URLs needed
--   for V1) while writes are tightly scoped to the owning user.
--
-- Object key convention:
--   <auth.uid()>/<feature>/<uuid>.<ext>
--   e.g.  3f5c.../listings/8b2e....jpg
--
--   The first path segment is the auth user id. RLS keys off that so a
--   user cannot write into another user's "folder". The `<feature>` segment
--   is informational only (helps humans browsing the bucket); we do not
--   enforce its values in the DB.
--
-- Watermarking:
--   The visible BP-XXXXXX watermark is burned in client-side before upload
--   (see lib/core/services/watermark_service.dart). The path-prefix RLS
--   here is the authoritative server-side owner-tag — it cannot be spoofed
--   by a misbehaving client.
--
-- Forward-only and idempotent: safe to re-run.

-- ---------------------------------------------------------------------------
-- 1. Bucket. Public so anyone can GET; mutations are gated by RLS below.
-- ---------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('user-uploads', 'user-uploads', TRUE)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

-- ---------------------------------------------------------------------------
-- 2. RLS policies on storage.objects scoped to this bucket.
--    storage.foldername(name) returns the path segments as a TEXT[]; the
--    first element is our owner user id.
-- ---------------------------------------------------------------------------

-- Public read.
DROP POLICY IF EXISTS user_uploads_public_read ON storage.objects;
CREATE POLICY user_uploads_public_read ON storage.objects
  FOR SELECT
  USING (bucket_id = 'user-uploads');

-- Authenticated insert into own folder.
DROP POLICY IF EXISTS user_uploads_owner_insert ON storage.objects;
CREATE POLICY user_uploads_owner_insert ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'user-uploads'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Authenticated update of own objects.
DROP POLICY IF EXISTS user_uploads_owner_update ON storage.objects;
CREATE POLICY user_uploads_owner_update ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'user-uploads'
    AND auth.uid()::text = (storage.foldername(name))[1]
  )
  WITH CHECK (
    bucket_id = 'user-uploads'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Authenticated delete of own objects.
DROP POLICY IF EXISTS user_uploads_owner_delete ON storage.objects;
CREATE POLICY user_uploads_owner_delete ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'user-uploads'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
