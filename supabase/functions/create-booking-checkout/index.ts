// Edge Function: create-booking-checkout
//
// Purpose:
//   Initiate a Stripe Checkout Session for a listing purchase. The function
//   creates a `bookings` row in `pending` state with the totals + platform
//   fee, then asks Stripe for a Checkout URL with `payment_intent_data`
//   wired for Connect transfers.
//
// Why server-side?
//   * Pricing must be authoritative — the client cannot be trusted to set
//     totals or fees.
//   * RLS prevents the client from inserting `bookings` with status='pending'
//     anyway; the service role here is the right tool.
//   * Lets us guard against missing seller stripe accounts before charging.
//
// Request body (JSON):
//   {
//     "listing_id": "<uuid>",
//     "quantity": 1,
//     "scheduled_for": "2025-01-01T19:00:00Z" // optional — services / events
//   }
//
// Response (JSON):
//   { "url": "https://checkout.stripe.com/...", "booking_id": "<uuid>" }
//
// Errors:
//   400 — bad payload, listing not active, etc.
//   401 — caller not authenticated.
//   404 — listing not found / hidden by RLS.
//   409 — seller hasn't completed Stripe Connect setup (charges_enabled=false).
//   500 — Stripe / Postgres failure.

// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const STRIPE_KEY = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
const SUCCESS_URL = Deno.env.get("STRIPE_CHECKOUT_SUCCESS_URL") ??
  "https://example.com/checkout/success?session_id={CHECKOUT_SESSION_ID}";
const CANCEL_URL = Deno.env.get("STRIPE_CHECKOUT_CANCEL_URL") ??
  "https://example.com/checkout/cancel";

// Lazy Stripe client; see create-stripe-connect-account for rationale.
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

  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: "bad_request" }, 400);
  }
  const listingId: string | undefined = body?.listing_id;
  const quantity: number = Number(body?.quantity ?? 1);
  const scheduledFor: string | undefined = body?.scheduled_for;
  const idempotencyKey: string = body?.idempotency_key ??
    crypto.randomUUID();

  if (!listingId || quantity < 1) return json({ error: "bad_request" }, 400);

  const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE);

  // 1. Resolve buyer profile id (the buyer's personal profile).
  const { data: buyerProfile } = await adminClient
    .from("profiles")
    .select("id")
    .eq("user_id", userId)
    .eq("profile_type", "personal")
    .maybeSingle();
  if (!buyerProfile) {
    return json({ error: "buyer_profile_required" }, 400);
  }

  // 2. Look up listing + seller's stripe account in one go via a join-ish
  //    select. Postgres-style nested selects keep this to a single round
  //    trip and let us bail early if anything is missing.
  const { data: listing, error: listingErr } = await adminClient
    .from("listings")
    .select(
      "id, profile_id, neighborhood_id, title, price_cents, currency, status, type",
    )
    .eq("id", listingId)
    .maybeSingle();
  if (listingErr || !listing) return json({ error: "listing_not_found" }, 404);
  if (listing.status !== "active") {
    return json({ error: "listing_not_active" }, 400);
  }
  if (listing.profile_id === buyerProfile.id) {
    return json({ error: "buyer_seller_must_differ" }, 400);
  }

  const { data: stripeAcct } = await adminClient
    .from("stripe_accounts")
    .select("stripe_account_id, charges_enabled")
    .eq("profile_id", listing.profile_id)
    .maybeSingle();
  if (!stripeAcct?.stripe_account_id || !stripeAcct.charges_enabled) {
    return json({ error: "seller_not_payable" }, 409);
  }

  // 3. Compute totals server-side. Platform fee = 8% of subtotal, ceiling.
  const unitPrice = Number(listing.price_cents);
  const subtotal = unitPrice * quantity;
  const platformFee = Math.ceil(subtotal * 0.08);
  const total = subtotal + platformFee;
  const currency = (listing.currency as string).toLowerCase();

  // 4. Insert pending booking. Idempotency key column is unique, so a
  //    retry with the same key returns the same row instead of creating
  //    a duplicate.
  const { data: insertedBooking, error: insertErr } = await adminClient
    .from("bookings")
    .upsert(
      {
        listing_id: listingId,
        buyer_profile_id: buyerProfile.id,
        seller_profile_id: listing.profile_id,
        neighborhood_id: listing.neighborhood_id,
        status: "pending",
        quantity,
        unit_price_cents: unitPrice,
        subtotal_cents: subtotal,
        platform_fee_cents: platformFee,
        total_cents: total,
        currency: listing.currency,
        scheduled_for: scheduledFor ?? null,
        idempotency_key: idempotencyKey,
      },
      { onConflict: "idempotency_key" },
    )
    .select("id")
    .single();
  if (insertErr || !insertedBooking) {
    return json(
      { error: "booking_insert_failed", detail: insertErr?.message },
      500,
    );
  }
  const bookingId = insertedBooking.id;

  // 5. Create the Stripe Checkout Session. `transfer_data.destination`
  //    routes the captured funds to the seller's connected account on
  //    success; `application_fee_amount` keeps the platform's cut on the
  //    platform balance.
  const session = await stripe.checkout.sessions.create({
    mode: "payment",
    success_url: SUCCESS_URL,
    cancel_url: CANCEL_URL,
    line_items: [
      {
        quantity,
        price_data: {
          currency,
          unit_amount: unitPrice,
          product_data: { name: listing.title },
        },
      },
    ],
    payment_intent_data: {
      application_fee_amount: platformFee,
      transfer_data: { destination: stripeAcct.stripe_account_id },
      metadata: {
        booking_id: bookingId,
        listing_id: listingId,
        buyer_profile_id: buyerProfile.id,
        seller_profile_id: listing.profile_id,
      },
    },
    metadata: {
      booking_id: bookingId,
      listing_id: listingId,
    },
  });

  return json({ url: session.url, booking_id: bookingId });
});

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
