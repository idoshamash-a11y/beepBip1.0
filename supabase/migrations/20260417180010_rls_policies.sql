-- Migration 10: Row Level Security policies
--
-- Guiding principles:
--   1. RLS is ON for every user-visible table. Default is deny.
--   2. Reads: public surfaces (active listings, visible profiles, non-expired
--      posts) are readable by anyone signed in. Private data (bookings,
--      payments, messages) is readable only by the parties involved.
--   3. Writes: users can only mutate their own rows. Money-moving tables
--      (payments, bookings status past 'pending') are NEVER written via the
--      client — those flow through SECURITY DEFINER RPCs or Stripe webhooks.
--   4. Admins (auth JWT `is_admin = true`) bypass via `public.is_admin()`.

-- ---------------------------------------------------------------------------
-- Enable RLS on all user-visible tables
-- ---------------------------------------------------------------------------
ALTER TABLE public.users                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personal_profiles     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_profiles     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_hours        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interests             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.neighborhoods         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listings              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stripe_accounts       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedback              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.disputes              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verifications         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banned_hashtags       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.muted_hashtags        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_flags         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_log       ENABLE ROW LEVEL SECURITY;

-- Helper: is the caller the owner of this profile?
CREATE OR REPLACE FUNCTION public.owns_profile(p_profile_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_profile_id AND p.user_id = auth.uid()
  );
$$;

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS users_select_self          ON public.users;
DROP POLICY IF EXISTS users_update_self          ON public.users;
DROP POLICY IF EXISTS users_admin_all            ON public.users;

CREATE POLICY users_select_self ON public.users
  FOR SELECT USING (id = auth.uid());

CREATE POLICY users_update_self ON public.users
  FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());

CREATE POLICY users_admin_all ON public.users
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS profiles_select_public  ON public.profiles;
DROP POLICY IF EXISTS profiles_insert_self    ON public.profiles;
DROP POLICY IF EXISTS profiles_update_self    ON public.profiles;
DROP POLICY IF EXISTS profiles_delete_self    ON public.profiles;
DROP POLICY IF EXISTS profiles_admin_all      ON public.profiles;

-- Anyone authenticated can see profiles that are 'open' visibility, OR their own.
CREATE POLICY profiles_select_public ON public.profiles
  FOR SELECT USING (
    visibility_status = 'open' OR user_id = auth.uid()
  );

CREATE POLICY profiles_insert_self ON public.profiles
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY profiles_update_self ON public.profiles
  FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY profiles_delete_self ON public.profiles
  FOR DELETE USING (user_id = auth.uid());

CREATE POLICY profiles_admin_all ON public.profiles
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ---------------------------------------------------------------------------
-- personal_profiles / business_profiles
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS pp_select     ON public.personal_profiles;
DROP POLICY IF EXISTS pp_write_self ON public.personal_profiles;

CREATE POLICY pp_select ON public.personal_profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = personal_profiles.id
        AND (p.visibility_status = 'open' OR p.user_id = auth.uid())
    )
  );

CREATE POLICY pp_write_self ON public.personal_profiles
  FOR ALL USING (public.owns_profile(id)) WITH CHECK (public.owns_profile(id));

DROP POLICY IF EXISTS bp_select     ON public.business_profiles;
DROP POLICY IF EXISTS bp_write_self ON public.business_profiles;

CREATE POLICY bp_select ON public.business_profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = business_profiles.id
        AND (p.visibility_status = 'open' OR p.user_id = auth.uid())
    )
  );

CREATE POLICY bp_write_self ON public.business_profiles
  FOR ALL USING (public.owns_profile(id)) WITH CHECK (public.owns_profile(id));

-- ---------------------------------------------------------------------------
-- business_hours
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS bh_select     ON public.business_hours;
DROP POLICY IF EXISTS bh_write_self ON public.business_hours;

CREATE POLICY bh_select ON public.business_hours
  FOR SELECT USING (TRUE);   -- business hours are public metadata

CREATE POLICY bh_write_self ON public.business_hours
  FOR ALL USING (public.owns_profile(business_profile_id))
           WITH CHECK (public.owns_profile(business_profile_id));

-- ---------------------------------------------------------------------------
-- interests (read-only canonical list)
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS interests_select ON public.interests;
DROP POLICY IF EXISTS interests_admin  ON public.interests;

CREATE POLICY interests_select ON public.interests FOR SELECT USING (TRUE);
CREATE POLICY interests_admin  ON public.interests FOR ALL
  USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ---------------------------------------------------------------------------
-- neighborhoods (read-only to users, writable by admins)
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS neigh_select ON public.neighborhoods;
DROP POLICY IF EXISTS neigh_admin  ON public.neighborhoods;

CREATE POLICY neigh_select ON public.neighborhoods FOR SELECT USING (TRUE);
CREATE POLICY neigh_admin  ON public.neighborhoods FOR ALL
  USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ---------------------------------------------------------------------------
-- locations
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS loc_select_public ON public.locations;
DROP POLICY IF EXISTS loc_write_self    ON public.locations;

-- Visible if owning profile is open OR location is coarse (we trust the client
-- to display accordingly; precise coords are only exposed to owner / party
-- in a booking via dedicated RPCs).
CREATE POLICY loc_select_public ON public.locations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = locations.profile_id
        AND (p.visibility_status = 'open' OR p.user_id = auth.uid())
    )
  );

CREATE POLICY loc_write_self ON public.locations
  FOR ALL USING (public.owns_profile(profile_id))
           WITH CHECK (public.owns_profile(profile_id));

-- ---------------------------------------------------------------------------
-- listings
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS listings_select_active ON public.listings;
DROP POLICY IF EXISTS listings_write_owner   ON public.listings;

CREATE POLICY listings_select_active ON public.listings
  FOR SELECT USING (
    status = 'active' OR public.owns_profile(profile_id)
  );

CREATE POLICY listings_write_owner ON public.listings
  FOR ALL USING (public.owns_profile(profile_id))
           WITH CHECK (public.owns_profile(profile_id));

-- ---------------------------------------------------------------------------
-- stripe_accounts (only self-visible, never self-writable)
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS sa_select_self ON public.stripe_accounts;
DROP POLICY IF EXISTS sa_admin       ON public.stripe_accounts;

CREATE POLICY sa_select_self ON public.stripe_accounts
  FOR SELECT USING (public.owns_profile(profile_id));

CREATE POLICY sa_admin ON public.stripe_accounts
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ---------------------------------------------------------------------------
-- bookings
--   Readable by buyer or seller.
--   Inserts allowed by buyer (pending only). All other mutations go through
--   SECURITY DEFINER RPCs (accept, pay, confirm, dispute, cancel).
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS bookings_select_parties ON public.bookings;
DROP POLICY IF EXISTS bookings_insert_buyer   ON public.bookings;
DROP POLICY IF EXISTS bookings_admin          ON public.bookings;

CREATE POLICY bookings_select_parties ON public.bookings
  FOR SELECT USING (
    public.owns_profile(buyer_profile_id) OR public.owns_profile(seller_profile_id)
  );

CREATE POLICY bookings_insert_buyer ON public.bookings
  FOR INSERT WITH CHECK (
    public.owns_profile(buyer_profile_id) AND status = 'pending'
  );

CREATE POLICY bookings_admin ON public.bookings
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ---------------------------------------------------------------------------
-- payments (read-only to booking parties; all writes via service role)
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS payments_select_parties ON public.payments;
DROP POLICY IF EXISTS payments_admin          ON public.payments;

CREATE POLICY payments_select_parties ON public.payments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = payments.booking_id
        AND (public.owns_profile(b.buyer_profile_id) OR public.owns_profile(b.seller_profile_id))
    )
  );

CREATE POLICY payments_admin ON public.payments
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ---------------------------------------------------------------------------
-- feedback
--   Published rows visible to anyone. Unpublished rows visible only to author.
--   Clients INSERT via submit_feedback RPC (SECURITY DEFINER), not directly.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS feedback_select ON public.feedback;
DROP POLICY IF EXISTS feedback_admin  ON public.feedback;

CREATE POLICY feedback_select ON public.feedback
  FOR SELECT USING (
    is_published
    OR public.owns_profile(author_profile_id)
    OR public.owns_profile(subject_profile_id)
  );

CREATE POLICY feedback_admin ON public.feedback
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ---------------------------------------------------------------------------
-- disputes
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS disputes_select_parties ON public.disputes;
DROP POLICY IF EXISTS disputes_insert_party   ON public.disputes;
DROP POLICY IF EXISTS disputes_admin          ON public.disputes;

CREATE POLICY disputes_select_parties ON public.disputes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = disputes.booking_id
        AND (public.owns_profile(b.buyer_profile_id) OR public.owns_profile(b.seller_profile_id))
    )
  );

CREATE POLICY disputes_insert_party ON public.disputes
  FOR INSERT WITH CHECK (
    public.owns_profile(opened_by) AND
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = disputes.booking_id
        AND (b.buyer_profile_id = opened_by OR b.seller_profile_id = opened_by)
    )
  );

CREATE POLICY disputes_admin ON public.disputes
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ---------------------------------------------------------------------------
-- posts
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS posts_select_active ON public.posts;
DROP POLICY IF EXISTS posts_write_owner   ON public.posts;

CREATE POLICY posts_select_active ON public.posts
  FOR SELECT USING (
    (NOT is_removed AND expires_at > NOW())
    OR public.owns_profile(author_profile_id)
  );

CREATE POLICY posts_write_owner ON public.posts
  FOR ALL USING (public.owns_profile(author_profile_id))
           WITH CHECK (public.owns_profile(author_profile_id));

-- ---------------------------------------------------------------------------
-- conversations / messages
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS conv_select_parties ON public.conversations;
DROP POLICY IF EXISTS conv_insert_party   ON public.conversations;
DROP POLICY IF EXISTS conv_update_party   ON public.conversations;

CREATE POLICY conv_select_parties ON public.conversations
  FOR SELECT USING (
    public.owns_profile(participant_a) OR public.owns_profile(participant_b)
  );

CREATE POLICY conv_insert_party ON public.conversations
  FOR INSERT WITH CHECK (
    public.owns_profile(participant_a) OR public.owns_profile(participant_b)
  );

CREATE POLICY conv_update_party ON public.conversations
  FOR UPDATE USING (
    public.owns_profile(participant_a) OR public.owns_profile(participant_b)
  );

DROP POLICY IF EXISTS msg_select_parties ON public.messages;
DROP POLICY IF EXISTS msg_insert_party   ON public.messages;

CREATE POLICY msg_select_parties ON public.messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = messages.conversation_id
        AND (public.owns_profile(c.participant_a) OR public.owns_profile(c.participant_b))
    )
  );

CREATE POLICY msg_insert_party ON public.messages
  FOR INSERT WITH CHECK (
    public.owns_profile(sender_profile_id)
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = messages.conversation_id
        AND (c.participant_a = messages.sender_profile_id OR c.participant_b = messages.sender_profile_id)
    )
    AND NOT is_system
  );

-- ---------------------------------------------------------------------------
-- verifications / reports (self-write, admin-read)
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS verifications_select ON public.verifications;
DROP POLICY IF EXISTS verifications_insert ON public.verifications;
DROP POLICY IF EXISTS verifications_admin  ON public.verifications;

CREATE POLICY verifications_select ON public.verifications
  FOR SELECT USING (public.owns_profile(profile_id) OR public.is_admin());

CREATE POLICY verifications_insert ON public.verifications
  FOR INSERT WITH CHECK (public.owns_profile(profile_id));

CREATE POLICY verifications_admin ON public.verifications
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS reports_insert_self ON public.reports;
DROP POLICY IF EXISTS reports_select_self ON public.reports;
DROP POLICY IF EXISTS reports_admin       ON public.reports;

CREATE POLICY reports_insert_self ON public.reports
  FOR INSERT WITH CHECK (public.owns_profile(reporter_profile_id));

CREATE POLICY reports_select_self ON public.reports
  FOR SELECT USING (public.owns_profile(reporter_profile_id) OR public.is_admin());

CREATE POLICY reports_admin ON public.reports
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ---------------------------------------------------------------------------
-- banned_hashtags / muted_hashtags / feature_flags / admin_audit_log
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS banned_select ON public.banned_hashtags;
DROP POLICY IF EXISTS banned_admin  ON public.banned_hashtags;
CREATE POLICY banned_select ON public.banned_hashtags FOR SELECT USING (TRUE);
CREATE POLICY banned_admin  ON public.banned_hashtags FOR ALL
  USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS muted_self ON public.muted_hashtags;
CREATE POLICY muted_self ON public.muted_hashtags
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS flags_select ON public.feature_flags;
DROP POLICY IF EXISTS flags_admin  ON public.feature_flags;
CREATE POLICY flags_select ON public.feature_flags FOR SELECT USING (TRUE);
CREATE POLICY flags_admin  ON public.feature_flags FOR ALL
  USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS audit_admin ON public.admin_audit_log;
CREATE POLICY audit_admin ON public.admin_audit_log
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
