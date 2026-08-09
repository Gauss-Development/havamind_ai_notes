// Pure tier-mapping helpers for the RevenueCat webhook. Kept in a separate
// module (no `Deno.serve`) so they can be unit-tested in isolation.
//
// Entitlement identifiers MUST match the client
// (lib/features/subscription/data/datasources/revenuecat_data_source.dart).
export const PRO_ENTITLEMENT = "Havamind Voice Pro";
export const BASIC_ENTITLEMENT = "Havamind Voice Basic";

export type Tier = "free" | "basic" | "pro";

/** Pro outranks Basic outranks Free. */
export function tierFromActiveEntitlements(activeIds: Iterable<string>): Tier {
  const set = new Set(activeIds);
  if (set.has(PRO_ENTITLEMENT)) return "pro";
  if (set.has(BASIC_ENTITLEMENT)) return "basic";
  return "free";
}

/**
 * Active = no expiry (lifetime) or expiry strictly in the future.
 * Mirrors how the RevenueCat REST v1 `subscribers` payload models
 * `entitlements[id].expires_date`.
 */
export function activeEntitlementIdsFromSubscriber(
  subscriber: {
    entitlements?: Record<string, { expires_date?: string | null }>;
  },
  nowMs: number,
): string[] {
  const ents = subscriber?.entitlements ?? {};
  const out: string[] = [];
  for (const [id, val] of Object.entries(ents)) {
    const exp = val?.expires_date ?? null;
    if (exp === null) {
      out.push(id);
      continue;
    }
    const t = Date.parse(exp);
    if (!Number.isNaN(t) && t > nowMs) out.push(id);
  }
  return out;
}
