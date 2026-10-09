/**
 * Concept rewrite rules for apply-debrief-to-thesis.
 * HTTP / OpenAI / Supabase I/O stays in index.ts.
 *
 * The live row in `theses` is the current speech. A debrief replaces that
 * speech in full. The speech someone already heard is a new `thesis_versions`
 * row and is not edited later. The hearer is a label on that row, not a user.
 */

export const PROMPT_VERSION = "concept-rewrite-v1";
export const CHAT_MODEL = "gpt-4o-mini";
export const WEEK_DEBRIEF_LIMIT = 5;
export const WEEK_WINDOW_DAYS = 7;
export const HEARER_LABEL_MAX = 120;
export const HEARER_REQUIRED = "HEARER_REQUIRED";
export const INCOMPLETE_REWRITE = "INCOMPLETE_REWRITE";

export const THESIS_TEXT_FIELDS = [
  "title",
  "short_summary",
  "problem",
  "solution",
  "target_audience",
  "business_model",
  "key_metrics",
  "advantages",
  "risks_gaps",
] as const;

export type ThesisTextField = (typeof THESIS_TEXT_FIELDS)[number];

export const EVIDENCE_KINDS = [
  "founder_claim",
  "customer_signal",
  "unbacked",
] as const;

export type EvidenceKind = (typeof EVIDENCE_KINDS)[number];

export type FieldEvidence = {
  kind: EvidenceKind;
  quote?: string | null;
  note_id?: string | null;
};

export type ThesisSnapshot = {
  title?: string | null;
  short_summary?: string | null;
  problem?: string | null;
  solution?: string | null;
  target_audience?: string | null;
  business_model?: string | null;
  key_metrics?: string | null;
  advantages?: string | null;
  risks_gaps?: string | null;
  follow_up_questions?: string[];
  next_conversation_script?: string | null;
  field_evidence?: Record<string, FieldEvidence>;
};

export type NoteAnalysis = {
  startup_title?: string | null;
  short_summary?: string | null;
  problem?: string | null;
  solution?: string | null;
  target_audience?: string | null;
  business_model?: string | null;
  key_metrics?: string | null;
  advantages?: string | null;
  risks_gaps?: string | null;
  follow_up_questions?: string[] | null;
};

export type HearingStatus = "unheard" | "heard";

export type RewriteGate =
  | { action: "require_hearer" }
  | { action: "rewrite_unheard" }
  | { action: "mark_heard"; heardByLabel: string };

const NOT_SPECIFIED_RE = /^(not\s*specified|не\s*указано|не\s*указан[аоы]?)$/i;

export function readBearerToken(
  authHeader: string | null | undefined,
): { ok: true; jwt: string } | { ok: false; status: 401; error: string } {
  if (!authHeader?.startsWith("Bearer ")) {
    return { ok: false, status: 401, error: "Missing authorization" };
  }
  const jwt = authHeader.slice("Bearer ".length).trim();
  if (!jwt) {
    return { ok: false, status: 401, error: "Missing authorization" };
  }
  return { ok: true, jwt };
}

export function parseNoteId(
  body: unknown,
): { ok: true; noteId: string } | { ok: false; status: 400; error: string } {
  if (!body || typeof body !== "object") {
    return { ok: false, status: 400, error: "Invalid JSON body" };
  }
  const noteId = (body as { note_id?: unknown }).note_id;
  if (!noteId || typeof noteId !== "string") {
    return { ok: false, status: 400, error: "note_id is required" };
  }
  return { ok: true, noteId };
}

export function normalizeHearerLabel(
  raw: unknown,
): { ok: true; label: string | null } | { ok: false; status: 400; error: string } {
  if (raw == null) return { ok: true, label: null };
  if (typeof raw !== "string") {
    return { ok: false, status: 400, error: "heard_by_label must be text" };
  }
  const label = raw.trim();
  if (label.length === 0) return { ok: true, label: null };
  if (label.length > HEARER_LABEL_MAX) {
    return {
      ok: false,
      status: 400,
      error: "heard_by_label must be 1–120 characters",
    };
  }
  return { ok: true, label };
}

export type ParsedApplyBody = {
  noteId: string;
  heardByLabel: string | null;
  rewriteUnheard: boolean;
  proposedRewrite: Record<string, unknown> | null;
};

export function parseApplyBody(
  body: unknown,
): { ok: true; value: ParsedApplyBody } | {
  ok: false;
  status: 400;
  error: string;
} {
  const note = parseNoteId(body);
  if (!note.ok) return note;
  const record = body as Record<string, unknown>;
  const label = normalizeHearerLabel(record.heard_by_label);
  if (!label.ok) return label;
  const proposed = record.proposed_rewrite;
  const proposedRewrite = proposed && typeof proposed === "object" &&
      !Array.isArray(proposed)
    ? proposed as Record<string, unknown>
    : null;
  return {
    ok: true,
    value: {
      noteId: note.noteId,
      heardByLabel: label.label,
      rewriteUnheard: record.rewrite_unheard === true,
      proposedRewrite,
    },
  };
}

/** A confirmed label is the heard path. Otherwise an explicit cold rewrite, or a suggestion. */
export function rewriteGate(opts: {
  heardByLabel: string | null;
  rewriteUnheard: boolean;
}): RewriteGate {
  if (opts.heardByLabel) {
    return { action: "mark_heard", heardByLabel: opts.heardByLabel };
  }
  if (opts.rewriteUnheard) return { action: "rewrite_unheard" };
  return { action: "require_hearer" };
}

/**
 * Suggestion calls the model once. A later confirm can send `proposed_rewrite`
 * with a hand-typed or accepted label and skip a second model call.
 */
export function modelCallRequired(opts: {
  gate: RewriteGate;
  proposedRewrite: Record<string, unknown> | null;
}): boolean {
  if (opts.gate.action === "require_hearer") return true;
  return opts.proposedRewrite == null;
}

export function assertNoteOwnership(
  noteUserId: string,
  requestUserId: string,
): { ok: true } | { ok: false; status: 403; error: string } {
  if (noteUserId !== requestUserId) {
    return { ok: false, status: 403, error: "Forbidden" };
  }
  return { ok: true };
}

/**
 * Concept rewrite is part of the free discovery loop.
 * Note-card refine-plan stays paid; this path must not 403 on `free`.
 */
export function isApplyBlockedForTier(_tier: string | null | undefined): boolean {
  return false;
}

export function isNoteReadyToApply(
  transcriptText: string | null | undefined,
): { ok: true } | { ok: false; status: 409; error: string; code: string } {
  if (!transcriptText || transcriptText.trim().length === 0) {
    return {
      ok: false,
      status: 409,
      error: "Note is not processed yet; transcript is required.",
      code: "NOTE_NOT_PROCESSED",
    };
  }
  return { ok: true };
}

export function isBlank(value: unknown): boolean {
  if (value == null) return true;
  if (typeof value !== "string") return String(value).trim().length === 0;
  const trimmed = value.trim();
  return trimmed.length === 0 || NOT_SPECIFIED_RE.test(trimmed);
}

export function thesisIsMostlyEmpty(thesis: ThesisSnapshot): boolean {
  return THESIS_TEXT_FIELDS.every((key) => isBlank(thesis[key]));
}

export function snapshotFromThesisRow(
  row: Record<string, unknown>,
): ThesisSnapshot {
  return {
    title: (row.title as string | null) ?? null,
    short_summary: (row.short_summary as string | null) ?? null,
    problem: (row.problem as string | null) ?? null,
    solution: (row.solution as string | null) ?? null,
    target_audience: (row.target_audience as string | null) ?? null,
    business_model: (row.business_model as string | null) ?? null,
    key_metrics: (row.key_metrics as string | null) ?? null,
    advantages: (row.advantages as string | null) ?? null,
    risks_gaps: (row.risks_gaps as string | null) ?? null,
    follow_up_questions: Array.isArray(row.follow_up_questions)
      ? (row.follow_up_questions as string[])
      : [],
    next_conversation_script:
      (row.next_conversation_script as string | null) ?? null,
    field_evidence: normalizeFieldEvidence(row.field_evidence, null),
  };
}

export function snapshotFromAnalysis(analysis: NoteAnalysis): ThesisSnapshot {
  return {
    title: analysis.startup_title ?? null,
    short_summary: analysis.short_summary ?? null,
    problem: analysis.problem ?? null,
    solution: analysis.solution ?? null,
    target_audience: analysis.target_audience ?? null,
    business_model: analysis.business_model ?? null,
    key_metrics: analysis.key_metrics ?? null,
    advantages: analysis.advantages ?? null,
    risks_gaps: analysis.risks_gaps ?? null,
    follow_up_questions: analysis.follow_up_questions ?? [],
    next_conversation_script: null,
    field_evidence: {},
  };
}

export function normalizeEvidenceKind(
  raw: unknown,
  fallback: EvidenceKind,
): EvidenceKind {
  if (typeof raw === "string" && (EVIDENCE_KINDS as readonly string[]).includes(raw)) {
    return raw as EvidenceKind;
  }
  return fallback;
}

export function defaultEvidenceKind(
  templateId: string | null | undefined,
  hasQuote: boolean,
): EvidenceKind {
  if (!hasQuote) return "unbacked";
  if (templateId === "customer_discovery") return "customer_signal";
  return "founder_claim";
}

export function normalizeFieldEvidence(
  raw: unknown,
  noteId: string | null,
  templateId?: string | null,
): Record<string, FieldEvidence> {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    return {};
  }
  const out: Record<string, FieldEvidence> = {};
  for (const [key, value] of Object.entries(raw as Record<string, unknown>)) {
    if (!value || typeof value !== "object" || Array.isArray(value)) continue;
    const entry = value as Record<string, unknown>;
    const quote = typeof entry.quote === "string" ? entry.quote : null;
    const kind = normalizeEvidenceKind(
      entry.kind,
      defaultEvidenceKind(templateId, !isBlank(quote)),
    );
    out[key] = {
      kind,
      quote,
      note_id: typeof entry.note_id === "string" ? entry.note_id : noteId,
    };
  }
  return out;
}

export function parseModelJson(
  raw: string,
): { ok: true; value: Record<string, unknown> } | { ok: false; error: string } {
  try {
    const value = JSON.parse(raw) as unknown;
    if (!value || typeof value !== "object" || Array.isArray(value)) {
      return { ok: false, error: "AI returned invalid JSON" };
    }
    return { ok: true, value: value as Record<string, unknown> };
  } catch {
    return { ok: false, error: "AI returned invalid JSON" };
  }
}

function clearedField(raw: string): string | null {
  const trimmed = raw.trim();
  if (trimmed.length === 0 || NOT_SPECIFIED_RE.test(trimmed)) return null;
  return trimmed;
}

function readFollowUps(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((item) => typeof item === "string" && item.trim().length > 0)
    .map((item) => (item as string).trim());
}

function readSuggestedHearer(raw: unknown): string | null {
  if (typeof raw !== "string") return null;
  const label = raw.trim();
  if (label.length === 0 || label.length > HEARER_LABEL_MAX) return null;
  return label;
}

export type RewriteResult = {
  ok: true;
  snapshot: ThesisSnapshot;
  rewriteNote: string;
  suggestedHearer: string | null;
} | {
  ok: false;
  status: 422;
  error: string;
  code: typeof INCOMPLETE_REWRITE;
};

/**
 * Replace every text field from the model. An empty field drops that piece.
 * A missing field on a non-empty concept rejects the whole rewrite.
 */
export function rewriteConcept(opts: {
  current: ThesisSnapshot;
  incoming: Record<string, unknown>;
}): RewriteResult {
  const currentNonEmpty = !thesisIsMostlyEmpty(opts.current);
  const snapshot: ThesisSnapshot = {
    follow_up_questions: readFollowUps(opts.incoming.follow_up_questions),
    next_conversation_script: null,
    field_evidence: {},
  };

  for (const key of THESIS_TEXT_FIELDS) {
    const raw = opts.incoming[key];
    if (typeof raw !== "string") {
      if (currentNonEmpty) {
        return {
          ok: false,
          status: 422,
          code: INCOMPLETE_REWRITE,
          error: "Rewrite omitted a concept field. Nothing was saved.",
        };
      }
      snapshot[key] = null;
      continue;
    }
    snapshot[key] = clearedField(raw);
  }

  const note = opts.incoming.rewrite_note;
  const rewriteNote = typeof note === "string" ? note.trim() : "";
  return {
    ok: true,
    snapshot,
    rewriteNote,
    suggestedHearer: readSuggestedHearer(opts.incoming.suggested_hearer),
  };
}

export function snapshotToProposedRewrite(
  snapshot: ThesisSnapshot,
  rewriteNote: string,
): Record<string, unknown> {
  const out: Record<string, unknown> = {
    follow_up_questions: snapshot.follow_up_questions ?? [],
    rewrite_note: rewriteNote,
  };
  for (const key of THESIS_TEXT_FIELDS) {
    const value = snapshot[key];
    out[key] = typeof value === "string" ? value : "";
  }
  return out;
}

export type VersionInsert = {
  thesis_id: string;
  user_id: string;
  round_number: number;
  thesis_snapshot: ThesisSnapshot;
  transcription: string;
  diff_summary: string | null;
  follow_up_questions: string[];
  source_note_id: string;
  source_template_id: string | null;
  hearing_status: HearingStatus;
  heard_by_label: string | null;
  heard_at: string | null;
};

export type ThesisUpdate = {
  title: string | null;
  short_summary: string | null;
  problem: string | null;
  solution: string | null;
  target_audience: string | null;
  business_model: string | null;
  key_metrics: string | null;
  advantages: string | null;
  risks_gaps: string | null;
  follow_up_questions: string[];
  next_conversation_script: null;
  field_evidence: Record<string, FieldEvidence>;
  debrief_count: number;
};

export type ConceptWritePlan = {
  heard: VersionInsert | null;
  thesis: ThesisUpdate;
  unheard: VersionInsert;
};

export function maxRoundNumber(
  rows: Array<{ round_number?: number | null }> | null | undefined,
): number {
  let max = 0;
  for (const row of rows ?? []) {
    const n = row.round_number ?? 0;
    if (typeof n === "number" && n > max) max = n;
  }
  return max;
}

export function cloneSnapshot(snapshot: ThesisSnapshot): ThesisSnapshot {
  return JSON.parse(JSON.stringify(snapshot)) as ThesisSnapshot;
}

function versionInsert(opts: {
  thesisId: string;
  userId: string;
  noteId: string;
  templateId: string | null;
  transcription: string;
  roundNumber: number;
  snapshot: ThesisSnapshot;
  diffSummary: string | null;
  hearingStatus: HearingStatus;
  heardByLabel: string | null;
  heardAt: string | null;
}): VersionInsert {
  return {
    thesis_id: opts.thesisId,
    user_id: opts.userId,
    round_number: opts.roundNumber,
    thesis_snapshot: cloneSnapshot(opts.snapshot),
    transcription: opts.transcription,
    diff_summary: opts.diffSummary,
    follow_up_questions: opts.snapshot.follow_up_questions ?? [],
    source_note_id: opts.noteId,
    source_template_id: opts.templateId,
    hearing_status: opts.hearingStatus,
    heard_by_label: opts.heardByLabel,
    heard_at: opts.heardAt,
  };
}

/**
 * Heard speech is inserted first. The new speech is a second, unheard row.
 * An empty concept has no speech to freeze, so no heard row is created.
 * Already stored rows are not part of this plan — callers only insert.
 */
export function planConceptRewrite(opts: {
  thesisId: string;
  userId: string;
  noteId: string;
  templateId: string | null;
  transcription: string;
  current: ThesisSnapshot;
  next: ThesisSnapshot;
  rewriteNote: string;
  priorMaxRound: number;
  heardByLabel: string | null;
  debriefCount: number;
  heardAt: string;
}): ConceptWritePlan {
  const freezeHeard = opts.heardByLabel != null &&
    !thesisIsMostlyEmpty(opts.current);
  const heardRound = opts.priorMaxRound + 1;
  const unheardRound = freezeHeard ? opts.priorMaxRound + 2 : opts.priorMaxRound + 1;
  const next = cloneSnapshot(opts.next);

  const heard = freezeHeard
    ? versionInsert({
      thesisId: opts.thesisId,
      userId: opts.userId,
      noteId: opts.noteId,
      templateId: opts.templateId,
      transcription: opts.transcription,
      roundNumber: heardRound,
      snapshot: opts.current,
      diffSummary: null,
      hearingStatus: "heard",
      heardByLabel: opts.heardByLabel,
      heardAt: opts.heardAt,
    })
    : null;

  const unheard = versionInsert({
    thesisId: opts.thesisId,
    userId: opts.userId,
    noteId: opts.noteId,
    templateId: opts.templateId,
    transcription: opts.transcription,
    roundNumber: unheardRound,
    snapshot: next,
    diffSummary: opts.rewriteNote || null,
    hearingStatus: "unheard",
    heardByLabel: null,
    heardAt: null,
  });

  return {
    heard,
    unheard,
    thesis: {
      title: next.title ?? null,
      short_summary: next.short_summary ?? null,
      problem: next.problem ?? null,
      solution: next.solution ?? null,
      target_audience: next.target_audience ?? null,
      business_model: next.business_model ?? null,
      key_metrics: next.key_metrics ?? null,
      advantages: next.advantages ?? null,
      risks_gaps: next.risks_gaps ?? null,
      follow_up_questions: next.follow_up_questions ?? [],
      next_conversation_script: null,
      field_evidence: {},
      debrief_count: nextDebriefCount(opts.debriefCount, opts.templateId),
    },
  };
}

export type ConceptDb = {
  insertVersion(row: VersionInsert): Promise<{ error: string | null }>;
  updateThesis(
    thesisId: string,
    patch: ThesisUpdate,
  ): Promise<{ error: string | null }>;
};

/** Insert the heard snapshot before touching `theses`. Never updates a version row. */
export async function commitConceptRewrite(
  db: ConceptDb,
  thesisId: string,
  plan: ConceptWritePlan,
): Promise<{ ok: true } | { ok: false; error: string }> {
  if (plan.heard) {
    const heard = await db.insertVersion(plan.heard);
    if (heard.error) return { ok: false, error: heard.error };
  }
  const updated = await db.updateThesis(thesisId, plan.thesis);
  if (updated.error) return { ok: false, error: updated.error };
  const unheard = await db.insertVersion(plan.unheard);
  if (unheard.error) return { ok: false, error: unheard.error };
  return { ok: true };
}

export type ExecuteRewriteInput = {
  gate: RewriteGate;
  current: ThesisSnapshot;
  modelJson: Record<string, unknown> | null;
  proposedRewrite: Record<string, unknown> | null;
  thesisId: string;
  userId: string;
  noteId: string;
  templateId: string | null;
  transcription: string;
  priorMaxRound: number;
  debriefCount: number;
  heardAt: string;
  db: ConceptDb;
};

export type ExecuteRewriteResult = {
  written: boolean;
  status: number;
  code?: string;
  error?: string;
  suggestedHearer: string | null;
  proposedRewrite: Record<string, unknown> | null;
  rewriteNote: string | null;
  updatedThesis: ThesisSnapshot | null;
  heardRound: number | null;
  unheardRound: number | null;
  debriefCount: number | null;
};

function emptyExecute(partial: Partial<ExecuteRewriteResult> & {
  status: number;
}): ExecuteRewriteResult {
  return {
    written: false,
    suggestedHearer: null,
    proposedRewrite: null,
    rewriteNote: null,
    updatedThesis: null,
    heardRound: null,
    unheardRound: null,
    debriefCount: null,
    ...partial,
  };
}

export async function executeConceptRewrite(
  input: ExecuteRewriteInput,
): Promise<ExecuteRewriteResult> {
  const incoming = input.gate.action === "require_hearer"
    ? input.modelJson
    : (input.proposedRewrite ?? input.modelJson);
  if (!incoming) {
    return emptyExecute({ status: 500, error: "Missing rewrite" });
  }

  const rewritten = rewriteConcept({
    current: input.current,
    incoming,
  });
  if (!rewritten.ok) {
    return emptyExecute({
      status: rewritten.status,
      code: rewritten.code,
      error: rewritten.error,
    });
  }

  if (input.gate.action === "require_hearer") {
    return emptyExecute({
      status: 422,
      code: HEARER_REQUIRED,
      error: "Confirm who heard this speech before rewriting the concept.",
      suggestedHearer: rewritten.suggestedHearer,
      proposedRewrite: snapshotToProposedRewrite(
        rewritten.snapshot,
        rewritten.rewriteNote,
      ),
      rewriteNote: rewritten.rewriteNote,
    });
  }

  const plan = planConceptRewrite({
    thesisId: input.thesisId,
    userId: input.userId,
    noteId: input.noteId,
    templateId: input.templateId,
    transcription: input.transcription,
    current: input.current,
    next: rewritten.snapshot,
    rewriteNote: rewritten.rewriteNote,
    priorMaxRound: input.priorMaxRound,
    heardByLabel: input.gate.action === "mark_heard"
      ? input.gate.heardByLabel
      : null,
    debriefCount: input.debriefCount,
    heardAt: input.heardAt,
  });
  const committed = await commitConceptRewrite(input.db, input.thesisId, plan);
  if (!committed.ok) {
    return emptyExecute({ status: 500, error: committed.error });
  }

  return {
    written: true,
    status: 200,
    suggestedHearer: null,
    proposedRewrite: null,
    rewriteNote: rewritten.rewriteNote,
    updatedThesis: plan.unheard.thesis_snapshot,
    heardRound: plan.heard?.round_number ?? null,
    unheardRound: plan.unheard.round_number,
    debriefCount: plan.thesis.debrief_count,
  };
}

/** Same id as Flutter `RecordingTemplateIds.customerDiscovery`. */
export const DEBRIEF_TEMPLATE_ID = "customer_discovery";

export function countsAsDebriefReturn(
  templateId: string | null | undefined,
): boolean {
  return templateId === DEBRIEF_TEMPLATE_ID;
}

/** Cold pitch / investor update keep [currentCount]; a customer-discovery note adds one. */
export function nextDebriefCount(
  currentCount: number,
  templateId: string | null | undefined,
): number {
  const n = Number.isFinite(currentCount)
    ? Math.max(0, Math.floor(currentCount))
    : 0;
  return countsAsDebriefReturn(templateId) ? n + 1 : n;
}

export function weekWindowStart(now = new Date()): string {
  const start = new Date(now.getTime() - WEEK_WINDOW_DAYS * 24 * 60 * 60 * 1000);
  return start.toISOString();
}

export const APPLY_SYSTEM_PROMPT =
  `You rewrite a founder's pitch concept after they debrief a speech they just gave.

Return a complete new speech they can say from the beginning. Do not append sentences onto the old fields. Do not keep an old sentence unless you deliberately say it again inside the new speech. An empty string means that piece is gone from the new speech.

Write in the language of the transcription (English or Russian).

suggested_hearer is a short label of the person named in the transcript who heard this pitch, such as "Masha, advisor". Use an empty string when nobody is named. Do not invent a person. This is a suggestion for the founder to confirm, not an account id.

rewrite_note is one short sentence on why the speech changed. It is for the screen, not a paragraph to paste into the speech.

Return strictly JSON with every text field present, using "" for a piece that is gone:
{
  "title": "",
  "short_summary": "",
  "problem": "",
  "solution": "",
  "target_audience": "",
  "business_model": "",
  "key_metrics": "",
  "advantages": "",
  "risks_gaps": "",
  "follow_up_questions": ["", "", ""],
  "rewrite_note": "",
  "suggested_hearer": ""
}`;

export type WeekDebrief = {
  note_id: string;
  template_id?: string | null;
  created_at?: string | null;
  transcript?: string | null;
  title?: string | null;
};

export function buildApplyUserPrompt(opts: {
  thesis: ThesisSnapshot;
  transcription: string;
  analysis: NoteAnalysis | null;
  weekDebriefs: WeekDebrief[];
  templateId?: string | null;
}): string {
  let prompt = "=== CURRENT CONCEPT ===\n";
  prompt += JSON.stringify(opts.thesis, null, 2);
  prompt += "\n\n";

  if (opts.analysis) {
    prompt += "=== NOTE-LEVEL ANALYSIS (event, not the concept) ===\n";
    prompt += JSON.stringify(opts.analysis, null, 2);
    prompt += "\n\n";
  }

  if (opts.weekDebriefs.length > 0) {
    prompt += "=== OTHER NOTES THIS WEEK ===\n";
    for (const d of opts.weekDebriefs) {
      prompt += `\nNote ${d.note_id}`;
      if (d.template_id) prompt += ` (${d.template_id})`;
      prompt += ":\n";
      if (d.title) prompt += `Title: ${d.title}\n`;
      if (d.transcript) {
        const clipped = d.transcript.length > 400
          ? `${d.transcript.slice(0, 397)}...`
          : d.transcript;
        prompt += `${clipped}\n`;
      }
    }
    prompt += "\n";
  }

  if (opts.templateId) {
    prompt += `=== NOTE TEMPLATE ===\n${opts.templateId}\n\n`;
  }

  prompt += "=== DEBRIEF TRANSCRIPT ===\n";
  prompt += opts.transcription;
  return prompt;
}
