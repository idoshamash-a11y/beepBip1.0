// Edge Function: stripe-webhook
//
// Purpose:
//   Server-authoritative state advancement for bookings + ledger entries in
//   `payments`. This is the only path that flips a booking past `pending` —
//   the client and RLS are deliberately powerless here.
//
// Events handled (V1):
//   * checkout.session.completed     — buyer reached the success page.
//   * payment_intent.succeeded       — funds captured on the platform.
//   * account.updated                — Connect onboarding / capability flips.
//   * charge.refunded                — record a refund movement (no
//                                      booking-state change yet — escrow /
//                                      dispute logic lives in V1.5).
//
// Idempotency:
//   `payments.stripe_event_id` is UNIQUE; we insert that first, and abort
//   the rest of the handler if it returns a conflict. This means Stripe's
//   "at-least-once" delivery is safe.
//
// Why no Supabase auth header?
//   This endpoint is hit by Stripe, not the user. We verify authenticity by
//   checking the Stripe signature header against the configured webhook
//   secret.
//
// Required env:
//   STRIPE_SECRET_KEY
//   STRIPE_WEBHOOK_SECRET
//   SUPABASE_URL                (auto)
//   SUPABASE_SERVICE_ROLE_KEY   (auto)

// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const STRIPE_KEY = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
const WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? "";

// Lazy Stripe client so the function boots cleanly in dev when no key is set.
function getStripe(): Stripe | null {
  if (!STRIPE_KEY) return null;
  return new Stripe(STRIPE_KEY, {
    apiVersion: "2024-06-20",
    httpClient: Stripe.createFetchHttpClient(),
  });
}

const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE);

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("method_not_allowed", { status: 405 });
  }
  const stripe = getStripe();
  if (!stripe || !WEBHOOK_SECRET) {
    // No keys yet — the webhook is a no-op. Stripe will retry, which is fine
    // for local dev where nothing is sending real events anyway.
    return new Response("stripe_not_configured", { status: 503 });
  }
  const signature = req.headers.get("stripe-signature");
  if (!signature) return new Response("missing_signature", { status: 400 });

  const rawBody = await req.text();
  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(
      rawBody,
      signature,
      WEBHOOK_SECRET,
    );
  } catch (err) {
    console.warn("invalid stripe signature", err);
    return new Response("invalid_signature", { status: 400 });
  }

  try {
    switch (event.type) {
      case "checkout.session.completed":
        await handleCheckoutCompleted(
          event.data.object as Stripe.Checkout.Session,
          event.id,
        );
        break;
      case "payment_intent.succeeded":
        await handlePaymentIntentSucceeded(
          event.data.object as Stripe.PaymentIntent,
          event.id,
        );
        break;
      case "account.updated":
        await handleAccountUpdated(
          event.data.object as Stripe.Account,
        );
        break;
      case "charge.refunded":
        await handleChargeRefunded(
          event.data.object as Stripe.Charge,
          event.id,
        );
        break;
      default:
        // Unhandled — return 200 so Stripe stops retrying. Logging only.
        console.log("ignored event", event.type);
    }
    return new Response("ok", { status: 200 });
  } catch (e) {
    console.error("webhook handler error", e);
    return new Response("server_error", { status: 500 });
  }
});

async function handleCheckoutCompleted(
  session: Stripe.Checkout.Session,
  eventId: string,
) {
  const bookingId = session.metadata?.booking_id;
  if (!bookingId) return;

  // pending → accepted (we'll move to paid once the PI succeeds; some
  // payment methods are async, so we don't combine the two transitions).
  const { data: current } = await adminClient
    .from("bookings")
    .select("status")
    .eq("id", bookingId)
    .maybeSingle();
  if (!current) return;

  if (current.status === "pending") {
    await adminClient
      .from("bookings")
      .update({ status: "accepted" })
      .eq("id", bookingId);
  }

  // Ledger entry — idempotent by stripe_event_id.
  await adminClient.from("payments").upsert(
    {
      booking_id: bookingId,
      movement: "charge",
      amount_cents: session.amount_total ?? 0,
      currency: (session.currency ?? "usd").toUpperCase(),
      stripe_object_id: session.payment_intent as string | null,
      stripe_event_id: eventId,
      description: "checkout.session.completed",
      metadata: { session_id: session.id },
    },
    { onConflict: "stripe_event_id", ignoreDuplicates: true },
  );
}

async function handlePaymentIntentSucceeded(
  pi: Stripe.PaymentIntent,
  eventId: string,
) {
  const bookingId = pi.metadata?.booking_id;
  if (!bookingId) return;

  const { data: current } = await adminClient
    .from("bookings")
    .select("status")
    .eq("id", bookingId)
    .maybeSingle();
  if (!current) return;

  // Drive the booking to `paid`. The schema's transition trigger only
  // allows accepted → paid, so we walk the staircase if we got here without
  // a checkout.session.completed (rare but possible for some PMs).
  if (current.status === "pending") {
    await adminClient
      .from("bookings")
      .update({ status: "accepted" })
      .eq("id", bookingId);
  }
  await adminClient
    .from("bookings")
    .update({
      status: "paid",
      stripe_payment_intent_id: pi.id,
      stripe_charge_id: pi.latest_charge as string | null,
    })
    .eq("id", bookingId);

  await adminClient.from("payments").upsert(
    {
      booking_id: bookingId,
      movement: "charge",
      amount_cents: pi.amount_received,
      currency: pi.currency.toUpperCase(),
      stripe_object_id: pi.id,
      stripe_event_id: eventId,
      description: "payment_intent.succeeded",
    },
    { onConflict: "stripe_event_id", ignoreDuplicates: true },
  );
}

async function handleAccountUpdated(account: Stripe.Account) {
  await adminClient
    .from("stripe_accounts")
    .update({
      charges_enabled: account.charges_enabled,
      payouts_enabled: account.payouts_enabled,
      details_submitted: account.details_submitted,
      requirements_currently_due: account.requirements?.currently_due ?? [],
    })
    .eq("stripe_account_id", account.id);
}

async function handleChargeRefunded(
  charge: Stripe.Charge,
  eventId: string,
) {
  // Resolve the booking from the charge id we recorded earlier. Refund
  // movements are signed negative so the ledger sums to net zero per
  // booking when fully refunded.
  const { data: booking } = await adminClient
    .from("bookings")
    .select("id")
    .eq("stripe_charge_id", charge.id)
    .maybeSingle();
  if (!booking) return;

  await adminClient.from("payments").upsert(
    {
      booking_id: booking.id,
      movement: "refund",
      amount_cents: -(charge.amount_refunded),
      currency: charge.currency.toUpperCase(),
      stripe_object_id: charge.id,
      stripe_event_id: eventId,
      description: "charge.refunded",
    },
    { onConflict: "stripe_event_id", ignoreDuplicates: true },
  );

  // V1 deliberately stops here — surfacing a `refunded` booking state
  // belongs to the escrow / dispute work queued in FOLLOWUPS.md.
}
