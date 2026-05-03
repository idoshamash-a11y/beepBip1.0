#!/usr/bin/env -S deno run --allow-net --allow-env --allow-read
/**
 * CLI mirror of the `dev-seed-mockups` Edge Function `load` path.
 *
 * Use when local Edge Functions cannot boot (e.g. Docker cannot reach
 * registry.npmjs.org). Reads the same dataset as
 * `supabase/functions/dev-seed-mockups/mockups.ts`.
 *
 *   # From repo root (beepBip1.0):
 *   export SUPABASE_URL=http://127.0.0.1:54321
 *   export SUPABASE_SERVICE_ROLE_KEY="$(supabase status -o env | grep SERVICE_ROLE | cut -d= -f2-)"
 *   deno run --allow-net --allow-env --allow-read scripts/run_mockup_seed.ts
 *
 * Optional: pass `--clear` first to delete all @mockup.beepbip users.
 */
import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  MOCK_BUSINESSES,
  MOCK_PERSONAL,
  MOCKUP_EMAIL_DOMAIN,
  MOCKUP_PASSWORD,
} from "../supabase/functions/dev-seed-mockups/mockups.ts";

const url = Deno.env.get("SUPABASE_URL") ?? "http://127.0.0.1:54321";
const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const args = Deno.args;

if (!serviceRole) {
  console.error("Set SUPABASE_SERVICE_ROLE_KEY (service role / secret from `supabase status`).");
  Deno.exit(1);
}

const admin = createClient(url, serviceRole, {
  auth: { autoRefreshToken: false, persistSession: false },
});

async function listMockupUserIds(client: SupabaseClient): Promise<string[]> {
  const { data, error } = await client
    .from("users")
    .select("id")
    .ilike("email", `%@${MOCKUP_EMAIL_DOMAIN}`);
  if (error) throw error;
  return (data ?? []).map((row: { id: string }) => row.id);
}

async function clearMockups(client: SupabaseClient) {
  const userIds = await listMockupUserIds(client);
  for (const id of userIds) {
    const { error } = await client.auth.admin.deleteUser(id);
    if (error) console.warn(`deleteUser ${id}: ${error.message}`);
  }
}

async function ensureMockUser(client: SupabaseClient, handle: string): Promise<string> {
  const email = `${handle}@${MOCKUP_EMAIL_DOMAIN}`;
  const { data: existing } = await client.from("users").select("id").eq("email", email).maybeSingle();
  if (existing?.id) return existing.id as string;

  const { data: created, error } = await client.auth.admin.createUser({
    email,
    password: MOCKUP_PASSWORD,
    email_confirm: true,
    user_metadata: { mockup: true, handle },
  });
  if (error || !created.user) {
    throw new Error(`failed to create auth user ${email}: ${error?.message}`);
  }
  return created.user.id;
}

async function upsertProfile(
  client: SupabaseClient,
  userId: string,
  profileType: "personal" | "business",
): Promise<string> {
  const { data: existing } = await client
    .from("profiles")
    .select("id")
    .eq("user_id", userId)
    .eq("profile_type", profileType)
    .maybeSingle();
  if (existing?.id) {
    await client.from("profiles").update({
      is_profile_complete: true,
      visibility_status: "open",
      location_sharing: "visible_with_location",
    }).eq("id", existing.id);
    return existing.id as string;
  }

  const { data: inserted, error } = await client.from("profiles").insert({
    user_id: userId,
    profile_type: profileType,
    is_profile_complete: true,
    visibility_status: "open",
    location_sharing: "visible_with_location",
  }).select("id").single();
  if (error || !inserted) throw new Error(`failed to insert profile: ${error?.message}`);
  return inserted.id as string;
}

async function upsertPrimaryLocation(
  client: SupabaseClient,
  profileId: string,
  loc: { lat: number; lng: number; address: string },
) {
  const { data: existing } = await client
    .from("locations")
    .select("id")
    .eq("profile_id", profileId)
    .eq("is_primary", true)
    .maybeSingle();

  const payload = {
    profile_id: profileId,
    latitude: loc.lat,
    longitude: loc.lng,
    address_line_1: loc.address,
    city: "New York",
    state: "NY",
    country: "US",
    postal_code: "10012",
    is_primary: true,
  };

  if (existing?.id) {
    const { error } = await client.from("locations").update(payload).eq("id", existing.id);
    if (error) throw error;
  } else {
    const { error } = await client.from("locations").insert(payload);
    if (error) throw error;
  }
}

async function loadMockups(client: SupabaseClient) {
  const { data: nbhd, error: nbErr } = await client
    .from("neighborhoods")
    .select("id")
    .eq("slug", "soho-nyc")
    .single();
  if (nbErr || !nbhd) {
    throw new Error("Neighborhood 'soho-nyc' not found. Run `supabase db reset` first.");
  }
  const neighborhoodId = nbhd.id as string;

  for (const p of MOCK_PERSONAL) {
    const userId = await ensureMockUser(client, p.handle);
    const profileId = await upsertProfile(client, userId, "personal");

    const { error } = await client.from("personal_profiles").upsert({
      id: profileId,
      name: p.name,
      bio: p.bio,
      photo_url: p.photo_url,
      interests: p.interests,
      social_handles: p.social_handles,
      date_of_birth: p.date_of_birth,
      gender: p.gender,
    }, { onConflict: "id" });
    if (error) throw error;

    if (p.location) await upsertPrimaryLocation(client, profileId, p.location);

    if (p.posts) {
      for (const post of p.posts) {
        const { error: postErr } = await client.from("posts").insert({
          author_profile_id: profileId,
          neighborhood_id: neighborhoodId,
          content: post.content,
          images: post.images,
          hashtags: post.hashtags,
        });
        if (postErr) throw postErr;
      }
    }
  }

  for (const b of MOCK_BUSINESSES) {
    const userId = await ensureMockUser(client, b.handle);
    const profileId = await upsertProfile(client, userId, "business");

    const { error } = await client.from("business_profiles").upsert({
      id: profileId,
      business_name: b.business_name,
      logo_url: b.logo_url,
      cover_url: b.cover_url,
      description: b.description,
      category: b.category,
      services: b.services,
      hashtags: b.hashtags,
      social_handles: b.social_handles,
      website: b.website,
      phone: b.phone,
      email: `${b.handle}@${MOCKUP_EMAIL_DOMAIN}`,
    }, { onConflict: "id" });
    if (error) throw error;

    await client.from("business_hours").delete().eq("business_profile_id", profileId);
    if (b.hours.length > 0) {
      const { error: hoursErr } = await client.from("business_hours").insert(
        b.hours.map((h) => ({
          business_profile_id: profileId,
          day_of_week: h.day_of_week,
          open_time: h.open_time,
          close_time: h.close_time,
          is_closed: h.is_closed,
        })),
      );
      if (hoursErr) throw hoursErr;
    }

    await upsertPrimaryLocation(client, profileId, b.location);

    await client.from("listings").delete().eq("profile_id", profileId);
    for (const l of b.listings) {
      const { error: listingErr } = await client.from("listings").insert({
        profile_id: profileId,
        neighborhood_id: neighborhoodId,
        type: l.type,
        title: l.title,
        description: l.description,
        price_cents: l.price_cents,
        currency: "USD",
        duration_minutes: l.duration_minutes ?? null,
        capacity: l.capacity ?? null,
        stock: l.stock ?? null,
        images: l.images,
        hashtags: l.hashtags,
        status: "active",
        starts_at: l.starts_at ?? null,
        ends_at: l.ends_at ?? null,
      });
      if (listingErr) throw listingErr;
    }

    if (b.posts) {
      for (const post of b.posts) {
        const { error: postErr } = await client.from("posts").insert({
          author_profile_id: profileId,
          neighborhood_id: neighborhoodId,
          content: post.content,
          images: post.images,
          hashtags: post.hashtags,
        });
        if (postErr) throw postErr;
      }
    }
  }
}

if (args.includes("--clear")) {
  console.log("Clearing mockup users…");
  await clearMockups(admin);
}
console.log("Loading mockups…");
await loadMockups(admin);
console.log("Done.");
