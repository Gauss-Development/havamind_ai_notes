/**
 * Tests for apply-debrief-to-thesis.
 *
 * Run: deno test --allow-env --allow-net supabase/functions/apply-debrief-to-thesis/index.test.ts
 *
 * Coverage mirrors refine-plan (auth, ownership, body) plus the living-thesis
 * rules: free users can apply, append does not overwrite, contradiction
 * writes a new version mark and keeps the previous wording in the diff.
 */

import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  applyDebriefFunctionUrl,
  getOrCreateUserThesisId,
  linkNoteToUserThesis,
} from "../_shared/thesis_link.ts";
import {
  APPLY_SYSTEM_PROMPT,
  assertNoteOwnership,
  buildApplyUserPrompt,
  defaultEvidenceKind,
  ensureDiffKeepsContradiction,
  hydrateThesisForApply,
  isApplyBlockedForTier,
  isNoteReadyToApply,
  markContradiction,
  mergeAppliedThesis,
  mergeTextField,
  nextDebriefCount,
  nextRoundNumber,
  normalizeFieldEvidence,
  countsAsDebriefReturn,
  parseNoteId,
  readBearerToken,
  snapshotFromAnalysis,
  thesisIsMostlyEmpty,
} from "./apply_logic.ts";

const MOCK_USER_ID = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee";
const OTHER_USER_ID = "ffffffff-1111-2222-3333-444444444444";
const MOCK_NOTE_ID = "11111111-2222-3333-4444-555555555555";
const MOCK_THESIS_ID = "66666666-7777-8888-9999-aaaaaaaaaaaa";

// ── Auth ────────────────────────────────────────────────────────────

Deno.test("apply-debrief: rejects requests without Authorization header", () => {
  const result = readBearerToken(undefined);
  assertEquals(result.ok, false);
  if (!result.ok) {
    assertEquals(result.status, 401);
    assertEquals(result.error, "Missing authorization");
  }
});

Deno.test("apply-debrief: rejects empty bearer token", () => {
  const result = readBearerToken("Bearer ");
  assertEquals(result.ok, false);
  if (!result.ok) {
    assertEquals(result.status, 401);
  }
});

Deno.test("apply-debrief: accepts a Bearer JWT", () => {
  const result = readBearerToken("Bearer valid-jwt-token");
  assertEquals(result.ok, true);
  if (result.ok) {
    assertEquals(result.jwt, "valid-jwt-token");
  }
});

// ── Body / processed note ───────────────────────────────────────────

Deno.test("apply-debrief: rejects missing note_id", () => {
  const result = parseNoteId({ transcription: "hello" });
  assertEquals(result.ok, false);
  if (!result.ok) {
    assertEquals(result.status, 400);
    assertEquals(result.error, "note_id is required");
  }
});

Deno.test("apply-debrief: rejects unprocessed note without transcript", () => {
  const result = isNoteReadyToApply("   ");
  assertEquals(result.ok, false);
  if (!result.ok) {
    assertEquals(result.status, 409);
    assertEquals(result.code, "NOTE_NOT_PROCESSED");
  }
});

Deno.test("apply-debrief: processed note with transcript is ready", () => {
  const result = isNoteReadyToApply("Talked to three clinics today.");
  assertEquals(result.ok, true);
});

// ── Ownership ───────────────────────────────────────────────────────

Deno.test("apply-debrief: ownership check rejects another user's note", () => {
  const result = assertNoteOwnership(OTHER_USER_ID, MOCK_USER_ID);
  assertEquals(result.ok, false);
  if (!result.ok) {
    assertEquals(result.status, 403);
    assertEquals(result.error, "Forbidden");
  }
});

Deno.test("apply-debrief: ownership check allows the note owner", () => {
  const result = assertNoteOwnership(MOCK_USER_ID, MOCK_USER_ID);
  assertEquals(result.ok, true);
});

// ── Free apply (unlike refine-plan) ─────────────────────────────────

Deno.test("apply-debrief: free user is allowed to apply", () => {
  assertEquals(isApplyBlockedForTier("free"), false);
});

Deno.test("apply-debrief: basic and pro users are allowed to apply", () => {
  assertEquals(isApplyBlockedForTier("basic"), false);
  assertEquals(isApplyBlockedForTier("pro"), false);
});

// ── Append, do not overwrite ────────────────────────────────────────

Deno.test("apply-debrief: blank incoming keeps the current field", () => {
  const merged = mergeTextField("Clinics pay monthly", "not specified");
  assertEquals(merged, "Clinics pay monthly");
});

Deno.test("apply-debrief: empty thesis takes the incoming field", () => {
  const merged = mergeTextField("", "Doctors wait 3 weeks for labs");
  assertEquals(merged, "Doctors wait 3 weeks for labs");
});

Deno.test("apply-debrief: non-contradicting add appends instead of replacing", () => {
  const merged = mergeTextField(
    "Clinics pay monthly",
    "Also want on-site training",
  );
  assertStringIncludes(merged, "Clinics pay monthly");
  assertStringIncludes(merged, "Also want on-site training");
});

Deno.test("apply-debrief: hydrates an empty thesis from note-level analysis", () => {
  const empty = snapshotFromAnalysis({});
  assertEquals(thesisIsMostlyEmpty(empty), true);
  const hydrated = hydrateThesisForApply(empty, {
    startup_title: "Lab wait times",
    problem: "Doctors wait 3 weeks",
    short_summary: "Faster lab results",
  });
  assertEquals(hydrated.title, "Lab wait times");
  assertEquals(hydrated.problem, "Doctors wait 3 weeks");
});

// ── Contradiction keeps a diff ──────────────────────────────────────

Deno.test("apply-debrief: contradiction marks the field and keeps previous wording", () => {
  const marked = markContradiction(
    "Clinics, not individual doctors, pay",
    "Doctors pay out of pocket",
  );
  assertStringIncludes(marked, "Clinics, not individual doctors, pay");
  assertStringIncludes(marked, "[contradiction: was ");
  assertStringIncludes(marked, "Doctors pay out of pocket");
});

Deno.test("apply-debrief: contradiction merge writes a version diff that keeps the old claim", () => {
  const current = {
    title: "Doctor billing",
    short_summary: "Doctors pay out of pocket",
    problem: "Doctors pay out of pocket",
    solution: "SMS reminders",
    target_audience: "Individual doctors",
    business_model: "Per-doctor fee",
    key_metrics: "",
    advantages: "",
    risks_gaps: "",
    follow_up_questions: [],
    field_evidence: {
      problem: { kind: "founder_claim" as const, quote: "doctors pay", note_id: "old" },
    },
  };

  const merged = mergeAppliedThesis({
    current,
    incoming: {
      title: "Clinic billing",
      problem: "Clinics pay; doctors do not",
      target_audience: "Outpatient clinics",
      business_model: "Clinic subscription",
      next_conversation_script:
        "• Talk to a clinic ops lead\n• Do not ask doctors about personal spend",
      field_evidence: {
        problem: {
          kind: "customer_signal",
          quote: "we budget this at the clinic",
        },
        target_audience: { kind: "customer_signal", quote: "clinic ops" },
      },
      contradictions: [
        {
          field: "problem",
          previous: "Doctors pay out of pocket",
          current: "Clinics pay; doctors do not",
        },
        {
          field: "target_audience",
          previous: "Individual doctors",
          current: "Outpatient clinics",
        },
      ],
      // Deliberately omit the old wording — merge must still keep a diff.
      diff_summary: "Buyer changed after this week's debriefs",
    },
    noteId: MOCK_NOTE_ID,
    templateId: "customer_discovery",
  });

  assertStringIncludes(merged.snapshot.problem ?? "", "Clinics pay");
  assertStringIncludes(merged.snapshot.problem ?? "", "[contradiction: was ");
  assertStringIncludes(
    merged.snapshot.problem ?? "",
    "Doctors pay out of pocket",
  );
  assertStringIncludes(merged.diff_summary, "Doctors pay out of pocket");
  assertStringIncludes(merged.diff_summary, "Individual doctors");
  assertEquals(merged.contradictions.length, 2);
  assertEquals(merged.field_evidence.problem.kind, "customer_signal");
  assertEquals(merged.field_evidence.problem.note_id, MOCK_NOTE_ID);
  assertStringIncludes(
    merged.next_conversation_script,
    "Talk to a clinic ops lead",
  );

  // A new thesis_versions row would store this snapshot + diff (round N+1).
  const versionRow = {
    thesis_id: MOCK_THESIS_ID,
    round_number: nextRoundNumber(0),
    thesis_snapshot: merged.snapshot,
    diff_summary: merged.diff_summary,
    source_note_id: MOCK_NOTE_ID,
    source_template_id: "customer_discovery",
  };
  assertEquals(versionRow.round_number, 1);
  assertEquals(versionRow.source_template_id, "customer_discovery");
  assertStringIncludes(versionRow.diff_summary, "Doctors pay out of pocket");
});

Deno.test("apply-debrief: only customer_discovery increments debrief_count", () => {
  assertEquals(countsAsDebriefReturn("customer_discovery"), true);
  assertEquals(countsAsDebriefReturn("founder_pitch"), false);
  assertEquals(countsAsDebriefReturn("investor_update"), false);
  assertEquals(countsAsDebriefReturn(null), false);

  assertEquals(nextDebriefCount(0, "customer_discovery"), 1);
  assertEquals(nextDebriefCount(1, "customer_discovery"), 2);
  assertEquals(nextDebriefCount(2, "customer_discovery"), 3);
  assertEquals(nextDebriefCount(1, "founder_pitch"), 1);
  assertEquals(nextDebriefCount(Number.NaN, "customer_discovery"), 1);
});

Deno.test("apply-debrief: ensureDiffKeepsContradiction backfills missing previous text", () => {
  const diff = ensureDiffKeepsContradiction(
    "Updated buyer",
    [{
      field: "problem",
      previous: "Doctors pay out of pocket",
      current: "Clinics pay",
    }],
    { problem: "Doctors pay out of pocket" },
    { problem: "Clinics pay" },
  );
  assertStringIncludes(diff, "Doctors pay out of pocket");
  assertStringIncludes(diff, "Clinics pay");
});

// ── Evidence + script ───────────────────────────────────────────────

Deno.test("apply-debrief: field_evidence kinds normalize and default by template", () => {
  assertEquals(defaultEvidenceKind("customer_discovery", true), "customer_signal");
  assertEquals(defaultEvidenceKind("founder_pitch", true), "founder_claim");
  assertEquals(defaultEvidenceKind("customer_discovery", false), "unbacked");

  const evidence = normalizeFieldEvidence(
    { problem: { kind: "nope", quote: "waited 3 weeks" } },
    MOCK_NOTE_ID,
    "customer_discovery",
  );
  assertEquals(evidence.problem.kind, "customer_signal");
  assertEquals(evidence.problem.note_id, MOCK_NOTE_ID);
});

Deno.test("apply-debrief: missing next_conversation_script falls back to unbacked stakes", () => {
  const merged = mergeAppliedThesis({
    current: {
      problem: "Lab wait times",
      field_evidence: {},
    },
    incoming: {
      problem: "Lab wait times",
      follow_up_questions: ["Who owns the budget?"],
      field_evidence: {
        problem: { kind: "unbacked" },
      },
    },
    noteId: MOCK_NOTE_ID,
  });
  assertStringIncludes(merged.next_conversation_script, "unbacked");
  assertStringIncludes(merged.next_conversation_script, "Who owns the budget?");
});

Deno.test("apply-debrief: prompt includes current thesis, analysis, and transcript", () => {
  const prompt = buildApplyUserPrompt({
    thesis: { problem: "Doctors wait 3 weeks", title: "Labs" },
    transcription: "The clinic director said they pay, not the doctor.",
    analysis: { problem: "Doctors wait 3 weeks", startup_title: "Labs" },
    weekDebriefs: [{
      note_id: "week-1",
      template_id: "customer_discovery",
      transcript: "First clinic interview",
    }],
    templateId: "customer_discovery",
  });
  assertStringIncludes(prompt, "CURRENT THESIS");
  assertStringIncludes(prompt, "NOTE-LEVEL ANALYSIS");
  assertStringIncludes(prompt, "OTHER DEBRIEFS THIS WEEK");
  assertStringIncludes(prompt, "DEBRIEF TRANSCRIPT");
  assertStringIncludes(prompt, "clinic director");
  assertStringIncludes(APPLY_SYSTEM_PROMPT, "contradict");
});

// ── thesis_id wiring ────────────────────────────────────────────────

Deno.test("apply-debrief: function URL is the apply-debrief-to-thesis path", () => {
  assertEquals(
    applyDebriefFunctionUrl("https://proj.supabase.co/"),
    "https://proj.supabase.co/functions/v1/apply-debrief-to-thesis",
  );
});

Deno.test("apply-debrief: getOrCreateUserThesisId returns the existing row", async () => {
  const supabase = {
    from(table: string) {
      assertEquals(table, "theses");
      return {
        select() {
          return {
            eq() {
              return {
                maybeSingle: async () => ({
                  data: { id: MOCK_THESIS_ID },
                  error: null,
                }),
              };
            },
          };
        },
      };
    },
  };
  const id = await getOrCreateUserThesisId(supabase, MOCK_USER_ID);
  assertEquals(id, MOCK_THESIS_ID);
});

Deno.test("apply-debrief: linkNoteToUserThesis writes audio_notes.thesis_id", async () => {
  let updated: Record<string, unknown> | null = null;
  const supabase = {
    from(table: string) {
      if (table === "theses") {
        return {
          select() {
            return {
              eq() {
                return {
                  maybeSingle: async () => ({
                    data: { id: MOCK_THESIS_ID },
                    error: null,
                  }),
                };
              },
            };
          },
        };
      }
      if (table === "audio_notes") {
        return {
          update(row: Record<string, unknown>) {
            updated = row;
            return {
              eq() {
                return {
                  eq: async () => ({ error: null }),
                };
              },
            };
          },
        };
      }
      throw new Error(`unexpected table ${table}`);
    },
  };

  const thesisId = await linkNoteToUserThesis(
    supabase,
    MOCK_USER_ID,
    MOCK_NOTE_ID,
  );
  assertEquals(thesisId, MOCK_THESIS_ID);
  assertEquals(updated, { thesis_id: MOCK_THESIS_ID });
});
