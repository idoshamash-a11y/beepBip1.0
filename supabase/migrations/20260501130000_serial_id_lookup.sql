-- Migration 15: cross-user serial_id lookup via SECURITY DEFINER.
--
-- Why this exists:
--   `public.users` is gated by `users_select_self` (id = auth.uid()), so a
--   user cannot read another user's row. That's intentional — email and
--   phone live there. But the `serial_id` (BP-XXXXXX) is a deliberately
--   public identifier; we surface it next to user/business names so people
--   can copy and quote it (support tickets, attribution, dispute reports).
--
--   Rather than relax RLS on the whole table or denormalize `serial_id`
--   onto `public.profiles`, we expose it through a tightly-scoped
--   SECURITY DEFINER function. Only the serial_id column comes back; nothing
--   else is observable through this surface.
--
-- Forward-only and idempotent: safe to re-run.

-- ---------------------------------------------------------------------------
-- get_serial_id_for_profile
--   Resolves a `profiles.id` to the serial_id of its owning user.
--   Returns NULL if the profile does not exist (we don't differentiate
--   "doesn't exist" from "exists but you can't see it" — both render as no
--   chip in the UI).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_serial_id_for_profile(
  p_profile_id UUID
)
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT u.serial_id
  FROM public.profiles p
  JOIN public.users u ON u.id = p.user_id
  WHERE p.id = p_profile_id
  LIMIT 1;
$$;

-- Allow any authenticated client (and anon, for unauthenticated browse of
-- public business pages once that ships) to call the function.
GRANT EXECUTE ON FUNCTION public.get_serial_id_for_profile(UUID)
  TO authenticated, anon;

-- ---------------------------------------------------------------------------
-- get_serial_id_for_user
--   Same idea, keyed on the user id directly. Useful for paths where we
--   already have a `user_id` on hand (e.g. chat partners) and don't want a
--   double-hop through `profiles`.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_serial_id_for_user(
  p_user_id UUID
)
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT u.serial_id
  FROM public.users u
  WHERE u.id = p_user_id
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_serial_id_for_user(UUID)
  TO authenticated, anon;
