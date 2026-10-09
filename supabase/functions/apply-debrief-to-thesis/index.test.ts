/**
 * Tests for apply-debrief-to-thesis.
 *
 * Run: deno test --allow-env --allow-net supabase/functions/apply-debrief-to-thesis/index.test.ts
 *
 * A debrief replaces the concept. The speech already heard stays only in the
 * heard snapshot. Missing a hearer and missing rewrite_unheard writes nothing.
 */

import {
  assertEquals,
  assertNotEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  applyDebriefFunctionUrl,
  getOrCreateUserThesisId,
  linkNoteToUserThesis,
} from "../_shared/thesis_link.ts";
import {
  APPLY_SYSTEM_PROMPT,
  HEARER_REQUIRED,
  INCOMPLETE_REWRITE,
  PROMPT_VERSION,
  assertNoteOwnership,
  buildApplyUserPrompt,
  countsAsDebriefReturn,
  defaultEvidenceKind,
  executeConceptRewrite,
  isApplyBlockedForTier,
  isNoteReadyToApply,
  modelCallRequired,
  nextDebriefCount,
  normalizeFieldEvidence,
  parseNoteId,
  planConceptRewrite,
  readBearerToken,
  rewriteConcept,
  rewriteGate,
  snapshotFromAnalysis,
  thesisIsMostlyEmpty,
  type ConceptDb,
  type ThesisSnapshot,
  type VersionInsert,
} from "./apply_logic.ts";

const MOCK_USER_ID = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee";
const OTHER_USER_ID = "ffffffff-1111-2222-3333-444444444444";
const MOCK_NOTE_ID = "11111111-2222-3333-4444-555555555555";
const MOCK_THESIS_ID = "66666666-7777-8888-9999-aaaaaaaaaaaa";
const HEARD_AT = "2026-10-09T07:00:00.000Z";
const OLD_PHRASE = "Clinics pay monthly";
const NEW_PHRASE = "Doctors wait 3 weeks";
const JOINED = `${OLD_PHRASE}\n${NEW_PHRASE}`;

function concept(businessModel: string): ThesisSnapshot {
  return {
    title: "Labs",
    short_summary: "Faster labs",
    problem: OLD_PHRASE,
    solution: "Portal",
    target_audience: "Clinics",
    business_model: businessModel,
    key_metrics: "Turnaround",
    advantages: "Speed",
    risks_gaps: "Adoption",
    follow_up_questions: [],
    field_evidence: {},
  };
}

function modelSpeech(businessModel: string): Record<string, unknown> {
  return {
    title: "Labs",
    short_summary: "Faster labs",
    problem: NEW_PHRASE,
    solution: "Portal",
    target_audience: "Clinics",
    business_model: businessModel,
    key_metrics: "Turnaround",
    advantages: "Speed",
    risks_gaps: "Adoption",
    follow_up_questions: ["Who signs?"],
    rewrite_note: "The buyer changed.",
    suggested_hearer: "Маша",
  };
}

function throwingDb(message: string): ConceptDb {
  return {
    insertVersion: () => {
      throw new Error(message);
    },
    updateThesis: () => {
      throw new Error(message);
    },
  };
}

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

// ── Replace, do not append ──────────────────────────────────────────

Deno.test("apply-debrief: blank incoming clears the field", () => {
  const rewritten = rewriteConcept({
    current: concept(OLD_PHRASE),
    incoming: modelSpeech("not specified"),
  });
  assertEquals(rewritten.ok, true);
  if (rewritten.ok) {
    assertEquals(rewritten.snapshot.business_model, null);
    assertNotEquals(rewritten.snapshot.business_model, OLD_PHRASE);
  }
});

Deno.test("apply-debrief: empty concept takes the incoming field", () => {
  const empty = snapshotFromAnalysis({});
  assertEquals(thesisIsMostlyEmpty(empty), true);
  const rewritten = rewriteConcept({
    current: empty,
    incoming: { business_model: NEW_PHRASE },
  });
  assertEquals(rewritten.ok, true);
  if (rewritten.ok) {
    assertEquals(rewritten.snapshot.business_model, NEW_PHRASE);
    assertEquals(rewritten.snapshot.title, null);
  }
});

Deno.test("apply-debrief: non-contradicting field replaces instead of appending", () => {
  const rewritten = rewriteConcept({
    current: concept(OLD_PHRASE),
    incoming: modelSpeech(NEW_PHRASE),
  });
  assertEquals(rewritten.ok, true);
  if (!rewritten.ok) return;
  assertEquals(rewritten.snapshot.business_model, NEW_PHRASE);
  assertNotEquals(rewritten.snapshot.business_model, JOINED);
  assertEquals(rewritten.snapshot.problem, NEW_PHRASE);
  assertEquals(
    JSON.stringify(rewritten.snapshot).includes("[contradiction: was"),
    false,
  );
});

Deno.test("apply-debrief: incomplete rewrite of a filled concept writes nothing", async () => {
  const incoming = modelSpeech(NEW_PHRASE);
  delete incoming.risks_gaps;
  const result = await executeConceptRewrite({
    gate: { action: "mark_heard", heardByLabel: "Маша" },
    current: concept(OLD_PHRASE),
    modelJson: incoming,
    proposedRewrite: null,
    thesisId: MOCK_THESIS_ID,
    userId: MOCK_USER_ID,
    noteId: MOCK_NOTE_ID,
    templateId: "founder_pitch",
    transcription: "Masha heard the pitch.",
    priorMaxRound: 0,
    debriefCount: 0,
    heardAt: HEARD_AT,
    db: throwingDb("wrote a row"),
  });
  assertEquals(result.written, false);
  assertEquals(result.code, INCOMPLETE_REWRITE);
});

Deno.test("apply-debrief: heard snapshot keeps the old phrase and the live speech does not", () => {
  const plan = planConceptRewrite({
    thesisId: MOCK_THESIS_ID,
    userId: MOCK_USER_ID,
    noteId: MOCK_NOTE_ID,
    templateId: "founder_pitch",
    transcription: "Маша heard clinics pay monthly. Next time say doctors wait.",
    current: concept(OLD_PHRASE),
    next: {
      ...concept(NEW_PHRASE),
      problem: NEW_PHRASE,
    },
    rewriteNote: "The buyer changed.",
    priorMaxRound: 2,
    heardByLabel: "Маша",
    debriefCount: 0,
    heardAt: HEARD_AT,
  });

  assertEquals(plan.thesis.business_model, NEW_PHRASE);
  assertEquals(plan.thesis.problem, NEW_PHRASE);
  assertEquals(JSON.stringify(plan.thesis).includes("[contradiction: was"), false);
  assertEquals(JSON.stringify(plan.thesis).includes(JOINED), false);
  assertEquals(plan.heard?.thesis_snapshot.business_model, OLD_PHRASE);
  assertEquals(plan.heard?.thesis_snapshot.problem, OLD_PHRASE);
  assertEquals(plan.heard?.hearing_status, "heard");
  assertEquals(plan.heard?.heard_by_label, "Маша");
  assertEquals(plan.heard?.heard_at, HEARD_AT);
  assertEquals(plan.heard?.user_id, MOCK_USER_ID);
  assertNotEquals(plan.heard?.user_id, plan.heard?.heard_by_label);
  assertEquals(plan.unheard.hearing_status, "unheard");
  assertEquals(plan.unheard.heard_by_label, null);
  assertEquals(plan.unheard.thesis_snapshot.business_model, NEW_PHRASE);
  assertEquals(plan.heard?.round_number, 3);
  assertEquals(plan.unheard.round_number, 4);
});

Deno.test("apply-debrief: empty first pitch does not create a heard row", () => {
  const plan = planConceptRewrite({
    thesisId: MOCK_THESIS_ID,
    userId: MOCK_USER_ID,
    noteId: MOCK_NOTE_ID,
    templateId: "founder_pitch",
    transcription: "Here is the speech.",
    current: snapshotFromAnalysis({}),
    next: concept(NEW_PHRASE),
    rewriteNote: "First speech.",
    priorMaxRound: 0,
    heardByLabel: null,
    debriefCount: 0,
    heardAt: HEARD_AT,
  });
  assertEquals(plan.heard, null);
  assertEquals(plan.thesis.business_model, NEW_PHRASE);
  assertEquals(plan.unheard.hearing_status, "unheard");
  assertEquals(plan.unheard.round_number, 1);

  const labeledEmpty = planConceptRewrite({
    thesisId: MOCK_THESIS_ID,
    userId: MOCK_USER_ID,
    noteId: MOCK_NOTE_ID,
    templateId: "founder_pitch",
    transcription: "Here is the speech.",
    current: snapshotFromAnalysis({}),
    next: concept(NEW_PHRASE),
    rewriteNote: "First speech.",
    priorMaxRound: 0,
    heardByLabel: "Маша",
    debriefCount: 0,
    heardAt: HEARD_AT,
  });
  assertEquals(labeledEmpty.heard, null);
});

Deno.test("apply-debrief: no hearer and no rewrite_unheard writes nothing", async () => {
  const gate = rewriteGate({ heardByLabel: null, rewriteUnheard: false });
  assertEquals(gate.action, "require_hearer");
  const result = await executeConceptRewrite({
    gate,
    current: concept(OLD_PHRASE),
    modelJson: modelSpeech(NEW_PHRASE),
    proposedRewrite: null,
    thesisId: MOCK_THESIS_ID,
    userId: MOCK_USER_ID,
    noteId: MOCK_NOTE_ID,
    templateId: "founder_pitch",
    transcription: "Someone in the room.",
    priorMaxRound: 1,
    debriefCount: 0,
    heardAt: HEARD_AT,
    db: throwingDb("wrote without a hearer"),
  });
  assertEquals(result.written, false);
  assertEquals(result.status, 422);
  assertEquals(result.code, HEARER_REQUIRED);
  assertEquals(result.suggestedHearer, "Маша");
  assertEquals(result.proposedRewrite?.business_model, NEW_PHRASE);
});

Deno.test("apply-debrief: confirmed label can reuse a proposal without another model call", () => {
  const proposal = modelSpeech(NEW_PHRASE);
  assertEquals(
    modelCallRequired({
      gate: { action: "mark_heard", heardByLabel: "Маша, эдвайзер" },
      proposedRewrite: proposal,
    }),
    false,
  );
  assertEquals(
    modelCallRequired({
      gate: { action: "mark_heard", heardByLabel: "Маша, эдвайзер" },
      proposedRewrite: null,
    }),
    true,
  );
});

Deno.test("apply-debrief: hearer label is not stored as user_id", async () => {
  const inserted: VersionInsert[] = [];
  const db: ConceptDb = {
    insertVersion: (row) => {
      inserted.push(row);
      return Promise.resolve({ error: null });
    },
    updateThesis: () => Promise.resolve({ error: null }),
  };
  const result = await executeConceptRewrite({
    gate: { action: "mark_heard", heardByLabel: "Маша" },
    current: concept(OLD_PHRASE),
    modelJson: modelSpeech(NEW_PHRASE),
    proposedRewrite: null,
    thesisId: MOCK_THESIS_ID,
    userId: MOCK_USER_ID,
    noteId: MOCK_NOTE_ID,
    templateId: "founder_pitch",
    transcription: "Маша heard it.",
    priorMaxRound: 0,
    debriefCount: 0,
    heardAt: HEARD_AT,
    db,
  });
  assertEquals(result.written, true);
  const heard = inserted.find((row) => row.hearing_status === "heard");
  assertEquals(heard?.user_id, MOCK_USER_ID);
  assertEquals(heard?.heard_by_label, "Маша");
  assertNotEquals(heard?.user_id, "Маша");
  assertEquals(inserted.some((row) => row.user_id === "Маша"), false);
});

Deno.test("apply-debrief: failed heard insert does not update the concept", async () => {
  let thesisUpdated = false;
  const db: ConceptDb = {
    insertVersion: (row) => {
      if (row.hearing_status === "heard") {
        return Promise.resolve({ error: "insert failed" });
      }
      throw new Error("unheard row inserted after a failed freeze");
    },
    updateThesis: () => {
      thesisUpdated = true;
      return Promise.resolve({ error: null });
    },
  };
  const result = await executeConceptRewrite({
    gate: { action: "mark_heard", heardByLabel: "Маша" },
    current: concept(OLD_PHRASE),
    modelJson: modelSpeech(NEW_PHRASE),
    proposedRewrite: null,
    thesisId: MOCK_THESIS_ID,
    userId: MOCK_USER_ID,
    noteId: MOCK_NOTE_ID,
    templateId: "founder_pitch",
    transcription: "Маша heard it.",
    priorMaxRound: 4,
    debriefCount: 1,
    heardAt: HEARD_AT,
    db,
  });
  assertEquals(result.written, false);
  assertEquals(result.error, "insert failed");
  assertEquals(thesisUpdated, false);
});

Deno.test("apply-debrief: repeat apply does not change a saved thesis_snapshot", async () => {
  const saved: ThesisSnapshot = concept(OLD_PHRASE);
  const savedBytes = JSON.stringify(saved);
  const versions: Array<{
    thesis_snapshot: string;
    hearing_status: string;
    heard_by_label: string | null;
  }> = [{
    thesis_snapshot: savedBytes,
    hearing_status: "heard",
    heard_by_label: "Маша",
  }];
  const db: ConceptDb = {
    insertVersion: (row) => {
      versions.push({
        thesis_snapshot: JSON.stringify(row.thesis_snapshot),
        hearing_status: row.hearing_status,
        heard_by_label: row.heard_by_label,
      });
      return Promise.resolve({ error: null });
    },
    updateThesis: () => Promise.resolve({ error: null }),
  };
  const base = {
    current: concept(NEW_PHRASE),
    modelJson: modelSpeech("Clinics pay annually"),
    proposedRewrite: null,
    thesisId: MOCK_THESIS_ID,
    userId: MOCK_USER_ID,
    noteId: MOCK_NOTE_ID,
    templateId: "founder_pitch" as string | null,
    transcription: "Another meeting.",
    debriefCount: 1,
    heardAt: HEARD_AT,
    db,
  };
  await executeConceptRewrite({
    ...base,
    gate: { action: "mark_heard", heardByLabel: "Маша" },
    priorMaxRound: 1,
  });
  await executeConceptRewrite({
    ...base,
    gate: { action: "rewrite_unheard" },
    priorMaxRound: 3,
  });
  assertEquals(versions[0].thesis_snapshot, savedBytes);
  assertEquals(versions[0].hearing_status, "heard");
  assertEquals(versions[0].heard_by_label, "Маша");
  assertEquals(versions[0].thesis_snapshot.includes("[contradiction: was"), false);
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

// ── Evidence + prompt ───────────────────────────────────────────────

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

Deno.test("apply-debrief: prompt asks for a full rewrite in the transcript language", () => {
  const prompt = buildApplyUserPrompt({
    thesis: { problem: OLD_PHRASE, title: "Labs" },
    transcription: "The clinic director said they pay, not the doctor.",
    analysis: { problem: OLD_PHRASE, startup_title: "Labs" },
    weekDebriefs: [{
      note_id: "week-1",
      template_id: "founder_pitch",
      transcript: "First pitch",
    }],
    templateId: "founder_pitch",
  });
  assertStringIncludes(prompt, "CURRENT CONCEPT");
  assertStringIncludes(prompt, "NOTE-LEVEL ANALYSIS");
  assertStringIncludes(prompt, "DEBRIEF TRANSCRIPT");
  assertStringIncludes(prompt, "clinic director");
  assertEquals(PROMPT_VERSION, "concept-rewrite-v1");
  assertStringIncludes(APPLY_SYSTEM_PROMPT, "rewrite");
  assertEquals(APPLY_SYSTEM_PROMPT.includes("APPEND"), false);
  assertEquals(APPLY_SYSTEM_PROMPT.includes("[contradiction: was"), false);
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
