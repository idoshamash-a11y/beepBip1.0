// Edge Function: create-stripe-connect-account
//
// Purpose:
//   Kick off Stripe Connect (Standard) onboarding for a business profile.
//   Creates the Stripe account if missing, upserts a row in
//   `public.stripe_accounts`, and returns an Account Link URL the client
//   opens in an external browser.
//
// Why an Edge Function (and not the Flutter app)?
//   * Stripe secret key never reaches the client.
//   * RLS gives us a clean ownership check via auth.uid() <-> profiles.user_id.
//
// Request body (JSON):
//   { "profile_id": "<uuid>" }
//
// Response (JSON):
//   { "url": "https://connect.stripe.com/setup/...", "account_id": "acct_..." }
//
// Errors:
//   400 — bad payload or missing profile.
//   401 — caller not authenticated.
//   403 — caller doesn't own the profile.
//   500 — Stripe / Postgres failure.
//
// Required environment variables (set via `supabase secrets set ...`):
//   STRIPE_SECRET_KEY
//   STRIPE_CONNECT_RETURN_URL
//   STRIPE_CONNECT_REFRESH_URL
//   SUPABASE_URL                  (auto-populated by the platform)
//   SUPABASE_SERVICE_ROLE_KEY     (auto-populated by the platform)
//   SUPABASE_ANON_KEY             (auto-populated by the platform)

// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const STRIPE_KEY = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
const RETURN_URL = Deno.env.get("STRIPE_CONNECT_RETURN_URL") ??
  "https://example.com/stripe/return";
const REFRESH_URL = Deno.env.get("STRIPE_CONNECT_REFRESH_URL") ??
  "https://example.com/stripe/refresh";

// Lazy Stripe client — instantiating with an empty key throws synchronously,
// which would crash the whole function on boot in dev where keys aren't set.
// Building the client per request only when a real key is present means
// `supabase functions serve` stays healthy in demo mode and the function
// returns a clean 503 instead of a deployment-time error.
function getStripe(): Stripe | null {
  if (!STRIPE_KEY) return null;
  return new Stripe(STRIPE_KEY, {
    apiVersion: "2024-06-20",
    httpClient: Stripe.createFetchHttpClient(),
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }
  const stripe = getStripe();
  if (!stripe) {
    return json({
      error: "stripe_not_configured",
      hint:
        "STRIPE_SECRET_KEY is unset. Either set the secret or keep the client in `bookings.demo_mode` to use the mock checkout.",
    }, 503);
  }

  // 1. Identify the caller from the bearer token. We use the anon key
  //    against the gotrue endpoint so row-level security policies that key
  //    off auth.uid() apply to subsequent reads through this client.
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "unauthenticated" }, 401);

  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userRes, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userRes.user) {
    return json({ error: "unauthenticated" }, 401);
  }
  const userId = userRes.user.id;

  // 2. Validate body.
  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: "bad_request" }, 400);
  }
  const profileId: string | undefined = body?.profile_id;
  if (!profileId) return json({ error: "bad_request" }, 400);

  // 3. Confirm the caller owns this profile. RLS would also stop the read
  //    below, but a clean 403 is friendlier to debug than a 0-row response.
  const { data: profile, error: profileErr } = await userClient
    .from("profiles")
    .select("id, user_id, profile_type")
    .eq("id", profileId)
    .maybeSingle();
  if (profileErr) return json({ error: "profile_lookup_failed" }, 500);
  if (!profile) return json({ error: "profile_not_found" }, 404);
  if (profile.user_id !== userId) return json({ error: "forbidden" }, 403);
  if (profile.profile_type !== "business") {
    return json({ error: "only_business_profiles_can_connect" }, 400);
  }

  // 4. Use the service role for the rest — we'll write `stripe_accounts`
  //    rows that should be invisible to the user but readable by the app
  //    (separate read RLS policy lets the owner see fields like
  //    `charges_enabled`).
  const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE);

  // Reuse an existing Stripe account for this profile if we already created
  // one (idempotent — onboarding can be paused and resumed by the user).
  const { data: existing } = await adminClient
    .from("stripe_accounts")
    .select("stripe_account_id")
    .eq("profile_id", profileId)
    .maybeSingle();

  let accountId = existing?.stripe_account_id as string | undefined;
  if (!accountId) {
    const account = await stripe.accounts.create({
      type: "standard",
      metadata: { profile_id: profileId, user_id: userId },
    });
    accountId = account.id;
    await adminClient.from("stripe_accounts").upsert({
      profile_id: profileId,
      stripe_account_id: accountId,
      charges_enabled: account.charges_enabled,
      payouts_enabled: account.payouts_enabled,
      details_submitted: account.details_submitted,
      requirements_currently_due: account.requirements?.currently_due ?? [],
      country: account.country,
      default_currency: account.default_currency,
    }, { onConflict: "profile_id" });
  }

  const link = await stripe.accountLinks.create({
    account: accountId!,
    refresh_url: REFRESH_URL,
    return_url: RETURN_URL,
    type: "account_onboarding",
  });

  return json({ url: link.url, account_id: accountId });
});

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
