import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";
import {
  activeEntitlementIdsFromSubscriber,
  type Tier,
  tierFromActiveEntitlements,
} from "./tier.ts";

// RevenueCat → Supabase bridge. On every subscriber event RevenueCat POSTs
// here; we recompute the user's tier and write `profiles.subscription_tier`
// with the service-role key (which is exempt from the client-only guard
// triggers, keeping the column server-owned). This is the missing link that
// lets the Edge Functions and quota gates see a user's real entitlement.

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Event types that grant/confirm entitlement; tier is taken from the current
// REST state, or (fallback) from the event's entitlement_ids.
const GRANT_EVENTS = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "PRODUCT_CHANGE",
  "UNCANCELLATION",
  "NON_RENEWING_PURCHASE",
  "SUBSCRIPTION_EXTENDED",
  "TRANSFER",
]);

/** Length-independent comparison to avoid trivial timing leaks. */
function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/** Authoritative tier from RevenueCat REST; null if the lookup fails. */
async function fetchTierFromRest(
  restKey: string,
  appUserId: string,
  nowMs: number,
): Promise<Tier | null> {
  const res = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${
      encodeURIComponent(appUserId)
    }`,
    { headers: { Authorization: `Bearer ${restKey}` } },
  );
  if (!res.ok) {
    console.error(`RevenueCat REST lookup failed (${res.status})`);
    return null;
  }
  const json = (await res.json()) as {
    subscriber?: {
      entitlements?: Record<string, { expires_date?: string | null }>;
    };
  };
  if (!json.subscriber) return null;
  const active = activeEntitlementIdsFromSubscriber(json.subscriber, nowMs);
  return tierFromActiveEntitlements(active);
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const webhookAuth = Deno.env.get("REVENUECAT_WEBHOOK_AUTH");
  const restKey = Deno.env.get("REVENUECAT_REST_API_KEY");

  if (!supabaseUrl || !serviceKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    return jsonResponse({ error: "Server misconfiguration" }, 500);
  }
  if (!webhookAuth) {
    console.error("Missing REVENUECAT_WEBHOOK_AUTH");
    return jsonResponse({ error: "Server misconfiguration" }, 500);
  }

  // Shared-secret check: set the same value as the Authorization header in the
  // RevenueCat dashboard → Integrations → Webhooks.
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!safeEqual(authHeader, webhookAuth)) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  let payload: {
    event?: {
      type?: string;
      app_user_id?: string;
      original_app_user_id?: string;
      aliases?: string[];
      entitlement_ids?: string[] | null;
    };
  };
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const event = payload.event;
  if (!event) return jsonResponse({ error: "Missing event" }, 400);

  // The client sets appUserID to the Supabase user id, so only UUID-shaped ids
  // are actionable; anonymous RevenueCat ids ($RCAnonymousID:…) are ignored.
  const candidates = new Set<string>();
  for (
    const id of [
      event.app_user_id,
      event.original_app_user_id,
      ...(event.aliases ?? []),
    ]
  ) {
    if (typeof id === "string" && UUID_RE.test(id)) candidates.add(id);
  }
  if (candidates.size === 0) {
    return jsonResponse({ ok: true, skipped: "no mappable app_user_id" }, 200);
  }

  const nowMs = Date.now();
  const type = event.type ?? "";
  const primaryId = event.app_user_id && UUID_RE.test(event.app_user_id)
    ? event.app_user_id
    : [...candidates][0];

  // REST is authoritative (handles renewals and expirations uniformly); fall
  // back to the event payload when REST is unavailable.
  let tier: Tier | null = null;
  if (restKey) {
    tier = await fetchTierFromRest(restKey, primaryId, nowMs);
  }
  if (tier === null) {
    if (type === "EXPIRATION") {
      tier = "free";
    } else if (type === "CANCELLATION") {
      // Cancellation ≠ immediate loss; the entitlement persists until expiry.
      return jsonResponse(
        { ok: true, skipped: "cancellation (no change)" },
        200,
      );
    } else if (GRANT_EVENTS.has(type)) {
      tier = tierFromActiveEntitlements(event.entitlement_ids ?? []);
    } else {
      return jsonResponse({ ok: true, skipped: `unhandled type ${type}` }, 200);
    }
  }
  if (tier === null) {
    return jsonResponse({ error: "Could not determine tier" }, 500);
  }

  const supabase = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const ids = [...candidates];
  const { error } = await supabase
    .from("profiles")
    .upsert(
      ids.map((id) => ({ id, subscription_tier: tier })),
      { onConflict: "id" },
    );
  if (error) {
    console.error("Failed to update subscription_tier:", error.message);
    return jsonResponse({ error: "Failed to update subscription" }, 500);
  }

  return jsonResponse({ ok: true, tier, updated: ids.length }, 200);
});
