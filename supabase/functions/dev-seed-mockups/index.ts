// Edge Function: dev-seed-mockups
//
// Implementation uses only native `fetch` + `std/http/server` — no
// `@supabase/supabase-js` or other npm-backed imports. That avoids Edge
// runtime boot failures when the container cannot reach registry.npmjs.org
// (a common Docker / corporate-network issue).
//
// Request body (JSON): { "action": "load" | "clear" | "reload" | "status" }

// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import {
  MOCK_BUSINESSES,
  MOCK_PERSONAL,
  MOCKUP_EMAIL_DOMAIN,
  MOCKUP_PASSWORD,
} from "./mockups.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!.replace(/\/$/, "");
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ALLOW_DEV_SEED =
  (Deno.env.get("ALLOW_DEV_SEED") ?? "").toLowerCase() === "true";

type Action = "load" | "clear" | "reload" | "status";

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function isLocalUrl(url: string): boolean {
  try {
    const u = new URL(url);
    return (
      u.hostname === "127.0.0.1" ||
      u.hostname === "localhost" ||
      u.hostname === "kong" ||
      u.hostname === "host.docker.internal"
    );
  } catch {
    return false;
  }
}

async function readJson(res: Response): Promise<any> {
  const text = await res.text();
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

async function rest(
  method: string,
  pathWithQuery: string,
  body?: unknown,
  extraHeaders?: Record<string, string>,
): Promise<Response> {
  const url = `${SUPABASE_URL}/rest/v1/${pathWithQuery}`;
  const headers: Record<string, string> = {
    apikey: SERVICE_ROLE,
    Authorization: `Bearer ${SERVICE_ROLE}`,
    Accept: "application/json",
    ...extraHeaders,
  };
  if (body !== undefined) {
    headers["Content-Type"] = "application/json";
  }
  return await fetch(url, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

async function restJsonOrThrow(
  method: string,
  pathWithQuery: string,
  body?: unknown,
  extraHeaders?: Record<string, string>,
): Promise<any> {
  const res = await rest(method, pathWithQuery, body, extraHeaders);
  const data = await readJson(res);
  if (!res.ok) {
    throw new Error(
      `${method} /rest/v1/${pathWithQuery} → ${res.status}: ${JSON.stringify(data)}`,
    );
  }
  return data;
}

async function authAdmin(
  method: string,
  path: string,
  body?: unknown,
): Promise<any> {
  const url = `${SUPABASE_URL}/auth/v1/admin${path}`;
  const headers: Record<string, string> = {
    apikey: SERVICE_ROLE,
    Authorization: `Bearer ${SERVICE_ROLE}`,
    Accept: "application/json",
  };
  if (body !== undefined) headers["Content-Type"] = "application/json";
  const res = await fetch(url, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const data = await readJson(res);
  if (!res.ok) {
    throw new Error(
      `${method} ${path} → ${res.status}: ${JSON.stringify(data)}`,
    );
  }
  return data;
}

async function listMockupUserIds(): Promise<string[]> {
  const q =
    `select=id&email=ilike.${encodeURIComponent("%@" + MOCKUP_EMAIL_DOMAIN)}`;
  const rows = await restJsonOrThrow("GET", `users?${q}`);
  return (Array.isArray(rows) ? rows : []).map((r: { id: string }) => r.id);
}

async function getStatus(): Promise<Record<string, number>> {
  const userIds = await listMockupUserIds();
  if (userIds.length === 0) {
    return { personal: 0, business: 0, listings: 0, posts: 0 };
  }

  const inList = userIds.join(",");
  const profiles = await restJsonOrThrow(
    "GET",
    `profiles?select=id,profile_type&user_id=in.(${inList})`,
  ) as Array<{ id: string; profile_type: string }>;

  const profileIds = profiles.map((p) => p.id);
  if (profileIds.length === 0) {
    return { personal: 0, business: 0, listings: 0, posts: 0 };
  }

  const pIn = profileIds.join(",");
  const listings = await restJsonOrThrow(
    "GET",
    `listings?select=id&profile_id=in.(${pIn})`,
  ) as unknown[];
  const posts = await restJsonOrThrow(
    "GET",
    `posts?select=id&author_profile_id=in.(${pIn})`,
  ) as unknown[];

  return {
    personal: profiles.filter((p) => p.profile_type === "personal").length,
    business: profiles.filter((p) => p.profile_type === "business").length,
    listings: Array.isArray(listings) ? listings.length : 0,
    posts: Array.isArray(posts) ? posts.length : 0,
  };
}

async function clearMockups(): Promise<void> {
  const userIds = await listMockupUserIds();
  for (const id of userIds) {
    try {
      await authAdmin("DELETE", `/users/${id}`);
    } catch (e) {
      console.warn(`deleteUser ${id}:`, e);
    }
  }
}

async function ensureMockUser(handle: string): Promise<string> {
  const email = `${handle}@${MOCKUP_EMAIL_DOMAIN}`;
  const existing = await restJsonOrThrow(
    "GET",
    `users?select=id&email=eq.${encodeURIComponent(email)}&limit=1`,
  ) as Array<{ id: string }>;
  if (existing?.length) return existing[0].id;

  const created = await authAdmin("POST", "/users", {
    email,
    password: MOCKUP_PASSWORD,
    email_confirm: true,
    user_metadata: { mockup: true, handle },
  });
  const id = created?.id ?? created?.user?.id;
  if (!id) throw new Error(`auth admin createUser missing id: ${JSON.stringify(created)}`);
  return id as string;
}

async function upsertProfile(
  userId: string,
  profileType: "personal" | "business",
): Promise<string> {
  const rows = await restJsonOrThrow(
    "GET",
    `profiles?select=id&user_id=eq.${userId}&profile_type=eq.${profileType}&limit=1`,
  ) as Array<{ id: string }>;

  if (rows?.length) {
    const id = rows[0].id;
    await restJsonOrThrow(
      "PATCH",
      `profiles?id=eq.${id}`,
      {
        is_profile_complete: true,
        visibility_status: "open",
        location_sharing: "visible_with_location",
      },
    );
    return id;
  }

  const inserted = await restJsonOrThrow(
    "POST",
    "profiles",
    {
      user_id: userId,
      profile_type: profileType,
      is_profile_complete: true,
      visibility_status: "open",
      location_sharing: "visible_with_location",
    },
    { Prefer: "return=representation" },
  ) as Array<{ id: string }>;
  if (!inserted?.length) throw new Error("profile insert returned no rows");
  return inserted[0].id;
}

async function upsertPrimaryLocation(
  profileId: string,
  loc: { lat: number; lng: number; address: string },
) {
  const existing = await restJsonOrThrow(
    "GET",
    `locations?select=id&profile_id=eq.${profileId}&is_primary=eq.true&limit=1`,
  ) as Array<{ id: string }>;

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

  if (existing?.length) {
    await restJsonOrThrow(
      "PATCH",
      `locations?id=eq.${existing[0].id}`,
      payload,
    );
  } else {
    await restJsonOrThrow("POST", "locations", payload, {
      Prefer: "return=minimal",
    });
  }
}

async function restDelete(pathWithQuery: string): Promise<void> {
  const res = await rest("DELETE", pathWithQuery);
  if (!res.ok && res.status !== 404) {
    const t = await res.text();
    throw new Error(`DELETE /rest/v1/${pathWithQuery} → ${res.status}: ${t}`);
  }
}

async function deletePostsForProfile(profileId: string) {
  await restDelete(`posts?author_profile_id=eq.${profileId}`);
}

async function loadMockups(): Promise<void> {
  const nbRows = await restJsonOrThrow(
    "GET",
    "neighborhoods?select=id&slug=eq.soho-nyc&limit=1",
  ) as Array<{ id: string }>;
  if (!nbRows?.length) {
    throw new Error("Neighborhood 'soho-nyc' not found. Run `supabase db reset` first.");
  }
  const neighborhoodId = nbRows[0].id;

  for (const p of MOCK_PERSONAL) {
    const userId = await ensureMockUser(p.handle);
    const profileId = await upsertProfile(userId, "personal");

    await restJsonOrThrow(
      "POST",
      `personal_profiles?on_conflict=id`,
      {
        id: profileId,
        name: p.name,
        bio: p.bio,
        photo_url: p.photo_url,
        interests: p.interests,
        social_handles: p.social_handles,
        date_of_birth: p.date_of_birth,
        gender: p.gender,
      },
      {
        Prefer: "resolution=merge-duplicates,return=minimal",
      },
    );

    if (p.location) await upsertPrimaryLocation(profileId, p.location);

    if (p.posts?.length) {
      await deletePostsForProfile(profileId);
      for (const post of p.posts) {
        await restJsonOrThrow("POST", "posts", {
          author_profile_id: profileId,
          neighborhood_id: neighborhoodId,
          content: post.content,
          images: post.images,
          hashtags: post.hashtags,
        }, { Prefer: "return=minimal" });
      }
    }
  }

  for (const b of MOCK_BUSINESSES) {
    const userId = await ensureMockUser(b.handle);
    const profileId = await upsertProfile(userId, "business");

    await restJsonOrThrow(
      "POST",
      `business_profiles?on_conflict=id`,
      {
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
      },
      { Prefer: "resolution=merge-duplicates,return=minimal" },
    );

    await restDelete(`business_hours?business_profile_id=eq.${profileId}`);
    if (b.hours.length > 0) {
      await restJsonOrThrow(
        "POST",
        "business_hours",
        b.hours.map((h) => ({
          business_profile_id: profileId,
          day_of_week: h.day_of_week,
          open_time: h.open_time,
          close_time: h.close_time,
          is_closed: h.is_closed,
        })),
        { Prefer: "return=minimal" },
      );
    }

    await upsertPrimaryLocation(profileId, b.location);

    await restDelete(`listings?profile_id=eq.${profileId}`);
    for (const l of b.listings) {
      await restJsonOrThrow("POST", "listings", {
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
      }, { Prefer: "return=minimal" });
    }

    if (b.posts?.length) {
      await deletePostsForProfile(profileId);
      for (const post of b.posts) {
        await restJsonOrThrow("POST", "posts", {
          author_profile_id: profileId,
          neighborhood_id: neighborhoodId,
          content: post.content,
          images: post.images,
          hashtags: post.hashtags,
        }, { Prefer: "return=minimal" });
      }
    }
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  if (!isLocalUrl(SUPABASE_URL) && !ALLOW_DEV_SEED) {
    return json(
      {
        error: "refused_non_local",
        hint:
          "SUPABASE_URL does not look local and ALLOW_DEV_SEED is not 'true'.",
        url: SUPABASE_URL,
      },
      403,
    );
  }

  let body: { action?: Action } = {};
  try {
    body = await req.json();
  } catch {
    return json({ error: "bad_request" }, 400);
  }

  const action: Action = body.action ?? "status";

  try {
    if (action === "status") {
      return json({ action, ok: true, summary: await getStatus() });
    }
    if (action === "clear") {
      await clearMockups();
      return json({ action, ok: true, summary: await getStatus() });
    }
    if (action === "load") {
      await loadMockups();
      return json({ action, ok: true, summary: await getStatus() });
    }
    if (action === "reload") {
      await clearMockups();
      await loadMockups();
      return json({ action, ok: true, summary: await getStatus() });
    }
    return json({ error: "unknown_action", action }, 400);
  } catch (err) {
    console.error("dev-seed-mockups failed", err);
    return json(
      {
        error: "seed_failed",
        message: (err as Error).message ?? String(err),
        action,
      },
      500,
    );
  }
});
