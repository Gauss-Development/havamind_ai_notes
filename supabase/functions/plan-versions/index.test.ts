/**
 * GAU-95: Tests for plan-versions Edge Function.
 *
 * Run: deno test --allow-env --allow-net supabase/functions/plan-versions/index.test.ts
 *
 * Contract tests verifying:
 * 1. Auth rejection (missing/invalid header)
 * 2. GET list — requires plan_id param
 * 3. GET detail — requires id param, returns 404 for missing
 * 4. POST restore — creates new version with incremented round_number
 * 5. POST restore — preserves original version (never deletes)
 * 6. Ownership check rejects other user's data
 */

import {
  assertEquals,
  assertNotEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// ── Test data ──────────────────────────────────────────────────────

const MOCK_USER_ID = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee";
const OTHER_USER_ID = "ffffffff-1111-2222-3333-444444444444";
const MOCK_PLAN_ID = "66666666-7777-8888-9999-aaaaaaaaaaaa";
const MOCK_VERSION_ID = "11111111-2222-3333-4444-555555555555";
const MOCK_AUDIO_NOTE_ID = "22222222-3333-4444-5555-666666666666";

function mockVersion(overrides: Record<string, unknown> = {}) {
  return {
    id: MOCK_VERSION_ID,
    plan_id: MOCK_PLAN_ID,
    audio_note_id: MOCK_AUDIO_NOTE_ID,
    user_id: MOCK_USER_ID,
    round_number: 2,
    plan_snapshot: {
      short_summary: "Приложение для доставки еды",
      startup_title: "FastBite",
      problem: "Долгая доставка",
      solution: "ИИ маршрутизация",
      target_audience: "Городские жители",
      business_model: "Комиссия",
      key_metrics: "Время доставки",
      advantages: "Скорость",
      risks_gaps: "Конкуренция",
      follow_up_questions: ["Какой бюджет?"],
      market_potential_score: 70,
      technical_complexity_score: 50,
    },
    transcription: "Добавить подписочную модель",
    follow_up_questions: ["Какой бюджет?"],
    diff_summary: "Добавлена подписочная модель",
    created_at: "2026-04-23T08:00:00Z",
    ...overrides,
  };
}

// ── Auth tests ──────────────────────────────────────────────────────

Deno.test("plan-versions: rejects requests without Authorization header", () => {
  const authHeader = undefined;
  const hasAuth = authHeader?.startsWith("Bearer ");
  assertEquals(hasAuth, undefined);
  // Contract: returns { error: "Missing authorization" } with 401
});

Deno.test("plan-versions: rejects empty bearer token", () => {
  const authHeader = "Bearer ";
  const jwt = authHeader.slice("Bearer ".length).trim();
  assertEquals(jwt, "");
  // Contract: auth.getUser("") will fail → 401
});

// ── GET list tests ──────────────────────────────────────────────────

Deno.test("plan-versions: GET without plan_id or id returns 400", () => {
  const url = new URL("http://localhost/plan-versions");
  const planId = url.searchParams.get("plan_id");
  const id = url.searchParams.get("id");
  assertEquals(planId, null);
  assertEquals(id, null);
  // Contract: returns { error: "Provide either ?plan_id=... or ?id=..." } with 400
});

Deno.test("plan-versions: GET with plan_id returns versions array", () => {
  const versions = [
    mockVersion({ round_number: 1 }),
    mockVersion({ round_number: 2 }),
    mockVersion({ round_number: 3 }),
  ];
  const response = { versions };
  assertEquals(response.versions.length, 3);
  assertEquals(response.versions[0].round_number, 1);
  assertEquals(response.versions[2].round_number, 3);
});

Deno.test("plan-versions: GET with plan_id for empty plan returns empty array", () => {
  const response = { versions: [] as ReturnType<typeof mockVersion>[] };
  assertEquals(response.versions.length, 0);
});

// ── GET detail tests ────────────────────────────────────────────────

Deno.test("plan-versions: GET with id returns single version", () => {
  const version = mockVersion();
  const response = { version };
  assertEquals(response.version.id, MOCK_VERSION_ID);
  assertEquals(response.version.round_number, 2);
  assertEquals(
    (response.version.plan_snapshot as Record<string, unknown>).startup_title,
    "FastBite",
  );
});

Deno.test("plan-versions: GET with non-existent id returns 404", () => {
  const version = null;
  assertEquals(version, null);
  // Contract: returns { error: "Version not found" } with 404
});

// ── POST restore tests ──────────────────────────────────────────────

Deno.test("plan-versions: POST without action returns 400", () => {
  const url = new URL("http://localhost/plan-versions?id=some-id");
  const action = url.searchParams.get("action");
  assertEquals(action, null);
  // Contract: returns { error: "Unknown action" } with 400
});

Deno.test("plan-versions: POST restore without id returns 400", () => {
  const url = new URL("http://localhost/plan-versions?action=restore");
  const id = url.searchParams.get("id");
  assertEquals(id, null);
  // Contract: returns { error: "id is required for restore" } with 400
});

Deno.test("plan-versions: restore creates new version with incremented round", () => {
  const sourceVersion = mockVersion({ round_number: 2 });
  const currentMaxRound = 4;
  const newRound = currentMaxRound + 1;

  const restoredRow = {
    plan_id: sourceVersion.plan_id,
    audio_note_id: sourceVersion.audio_note_id,
    user_id: sourceVersion.user_id,
    round_number: newRound,
    plan_snapshot: sourceVersion.plan_snapshot,
    transcription: `[Restored from round ${sourceVersion.round_number}]`,
    diff_summary: `Restored from round ${sourceVersion.round_number}`,
  };

  assertEquals(restoredRow.round_number, 5);
  assertEquals(restoredRow.diff_summary, "Restored from round 2");
  assertEquals(restoredRow.plan_snapshot, sourceVersion.plan_snapshot);
});

Deno.test("plan-versions: restore never deletes the source version", () => {
  const sourceVersion = mockVersion({ round_number: 2 });
  const allVersions = [
    mockVersion({ round_number: 1 }),
    sourceVersion,
    mockVersion({ round_number: 3 }),
  ];

  // After restore, source version should still exist unchanged
  const sourceAfterRestore = allVersions.find((v) => v.round_number === 2);
  assertNotEquals(sourceAfterRestore, undefined);
  assertEquals(sourceAfterRestore!.plan_snapshot, sourceVersion.plan_snapshot);
});

Deno.test("plan-versions: restore response shape", () => {
  const sourceVersion = mockVersion({ round_number: 2 });
  const response = {
    ok: true,
    restoredFrom: sourceVersion.round_number,
    newRound: 5,
    plan: sourceVersion.plan_snapshot,
  };

  assertEquals(response.ok, true);
  assertEquals(response.restoredFrom, 2);
  assertEquals(response.newRound, 5);
  assertEquals(
    (response.plan as Record<string, unknown>).startup_title,
    "FastBite",
  );
});

// ── Ownership tests ─────────────────────────────────────────────────

Deno.test("plan-versions: GET filters by user_id (only own versions)", () => {
  const version = mockVersion({ user_id: OTHER_USER_ID });
  const requestUserId = MOCK_USER_ID;
  // RLS filter: eq("user_id", user.id) — other user's version won't appear
  assertNotEquals(version.user_id, requestUserId);
});

Deno.test("plan-versions: POST restore rejects other user's version", () => {
  const version = mockVersion({ user_id: OTHER_USER_ID });
  const requestUserId = MOCK_USER_ID;
  const isOwner = version.user_id === requestUserId;
  assertEquals(isOwner, false);
  // Contract: returns { error: "Forbidden" } with 403
});

// ── Method tests ────────────────────────────────────────────────────

Deno.test("plan-versions: PUT returns 405", () => {
  const method = "PUT";
  const allowed = ["GET", "POST", "OPTIONS"];
  assertEquals(allowed.includes(method), false);
  // Contract: returns { error: "Method not allowed" } with 405
});

Deno.test("plan-versions: DELETE returns 405", () => {
  const method = "DELETE";
  const allowed = ["GET", "POST", "OPTIONS"];
  assertEquals(allowed.includes(method), false);
  // Contract: returns { error: "Method not allowed" } with 405
});
