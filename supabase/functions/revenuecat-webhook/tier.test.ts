/**
 * Tests for the RevenueCat webhook tier-mapping helpers.
 *
 * Run: deno test supabase/functions/revenuecat-webhook/tier.test.ts
 */

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  activeEntitlementIdsFromSubscriber,
  BASIC_ENTITLEMENT,
  PRO_ENTITLEMENT,
  tierFromActiveEntitlements,
} from "./tier.ts";

Deno.test("tierFromActiveEntitlements: pro outranks basic", () => {
  assertEquals(
    tierFromActiveEntitlements([BASIC_ENTITLEMENT, PRO_ENTITLEMENT]),
    "pro",
  );
});

Deno.test("tierFromActiveEntitlements: basic when only basic active", () => {
  assertEquals(tierFromActiveEntitlements([BASIC_ENTITLEMENT]), "basic");
});

Deno.test("tierFromActiveEntitlements: free when nothing active", () => {
  assertEquals(tierFromActiveEntitlements([]), "free");
  assertEquals(tierFromActiveEntitlements(["Some Other Entitlement"]), "free");
});

Deno.test("activeEntitlementIdsFromSubscriber: future expiry is active", () => {
  const now = Date.parse("2026-01-01T00:00:00Z");
  const ids = activeEntitlementIdsFromSubscriber(
    {
      entitlements: {
        [PRO_ENTITLEMENT]: { expires_date: "2026-02-01T00:00:00Z" },
      },
    },
    now,
  );
  assertEquals(ids, [PRO_ENTITLEMENT]);
});

Deno.test("activeEntitlementIdsFromSubscriber: past expiry is inactive", () => {
  const now = Date.parse("2026-03-01T00:00:00Z");
  const ids = activeEntitlementIdsFromSubscriber(
    {
      entitlements: {
        [PRO_ENTITLEMENT]: { expires_date: "2026-02-01T00:00:00Z" },
      },
    },
    now,
  );
  assertEquals(ids, []);
});

Deno.test("activeEntitlementIdsFromSubscriber: null expiry is lifetime/active", () => {
  const now = Date.parse("2026-03-01T00:00:00Z");
  const ids = activeEntitlementIdsFromSubscriber(
    { entitlements: { [BASIC_ENTITLEMENT]: { expires_date: null } } },
    now,
  );
  assertEquals(ids, [BASIC_ENTITLEMENT]);
});

Deno.test("end-to-end: expired pro subscriber maps to free", () => {
  const now = Date.parse("2026-03-01T00:00:00Z");
  const active = activeEntitlementIdsFromSubscriber(
    {
      entitlements: {
        [PRO_ENTITLEMENT]: { expires_date: "2026-02-01T00:00:00Z" },
      },
    },
    now,
  );
  assertEquals(tierFromActiveEntitlements(active), "free");
});
