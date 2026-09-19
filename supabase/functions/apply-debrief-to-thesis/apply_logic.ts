/**
 * Testable rules for apply-debrief-to-thesis.
 * HTTP / OpenAI / Supabase I/O stays in index.ts.
 */

export const PROMPT_VERSION = "apply-debrief-v1";
export const CHAT_MODEL = "gpt-4o-mini";
export const WEEK_DEBRIEF_LIMIT = 5;
export const WEEK_WINDOW_DAYS = 7;

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

export type ThesisContradiction = {
  field: ThesisTextField;
  previous: string;
  current: string;
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

export type ApplyModelResponse = ThesisSnapshot & {
  contradictions?: ThesisContradiction[];
  diff_summary?: string | null;
};

export type MergedThesisApply = {
  snapshot: ThesisSnapshot;
  contradictions: ThesisContradiction[];
  diff_summary: string;
  field_evidence: Record<string, FieldEvidence>;
  next_conversation_script: string;
  follow_up_questions: string[];
};

const NOT_SPECIFIED_RE = /^(not\s*specified|не\s*указано|не\s*указан[аоы]?)$/i;
const CONTRADICTION_MARK_PREFIX = "[contradiction: was ";

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
 * Apply-to-thesis is part of the free discovery loop.
 * Note-level refine-plan stays paid; this path must not 403 on `free`.
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

export function hydrateThesisForApply(
  thesis: ThesisSnapshot,
  analysis: NoteAnalysis | null,
): ThesisSnapshot {
  if (!analysis || !thesisIsMostlyEmpty(thesis)) {
    return thesis;
  }
  return {
    ...snapshotFromAnalysis(analysis),
    field_evidence: thesis.field_evidence ?? {},
    next_conversation_script: thesis.next_conversation_script ?? null,
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
      note_id: typeof entry.note_id === "string"
        ? entry.note_id
        : noteId,
    };
  }
  return out;
}

export function stampEvidenceNoteId(
  evidence: Record<string, FieldEvidence>,
  noteId: string,
): Record<string, FieldEvidence> {
  const out: Record<string, FieldEvidence> = {};
  for (const [key, value] of Object.entries(evidence)) {
    out[key] = { ...value, note_id: value.note_id ?? noteId };
  }
  return out;
}

export function markContradiction(newValue: string, previous: string): string {
  const trimmedNew = newValue.trim();
  const trimmedPrev = previous.trim();
  if (trimmedNew.includes(CONTRADICTION_MARK_PREFIX)) {
    return trimmedNew;
  }
  const clipped = trimmedPrev.length > 160
    ? `${trimmedPrev.slice(0, 157).trimEnd()}...`
    : trimmedPrev;
  return `${trimmedNew} ${CONTRADICTION_MARK_PREFIX}"${clipped}"]`;
}

export function contradictionForField(
  contradictions: ThesisContradiction[],
  field: ThesisTextField,
): ThesisContradiction | undefined {
  return contradictions.find((c) => c.field === field);
}

export function mergeTextField(
  current: string | null | undefined,
  incoming: string | null | undefined,
  contradiction?: ThesisContradiction,
): string {
  const currentText = isBlank(current) ? "" : String(current).trim();
  const incomingText = isBlank(incoming) ? "" : String(incoming).trim();

  if (!incomingText) return currentText;
  if (!currentText) return incomingText;
  if (currentText === incomingText) return currentText;

  if (contradiction) {
    return markContradiction(incomingText, contradiction.previous || currentText);
  }

  // Append, do not replace: if the model already kept the old text, trust it.
  if (incomingText.includes(currentText)) return incomingText;
  return `${currentText}\n${incomingText}`;
}

export function normalizeContradictions(
  raw: unknown,
  current: ThesisSnapshot,
): ThesisContradiction[] {
  if (!Array.isArray(raw)) return [];
  const out: ThesisContradiction[] = [];
  for (const item of raw) {
    if (!item || typeof item !== "object") continue;
    const field = (item as { field?: unknown }).field;
    if (
      typeof field !== "string" ||
      !(THESIS_TEXT_FIELDS as readonly string[]).includes(field)
    ) {
      continue;
    }
    const typedField = field as ThesisTextField;
    const previousRaw = (item as { previous?: unknown }).previous;
    const currentRaw = (item as { current?: unknown }).current;
    const previous = typeof previousRaw === "string" && previousRaw.trim()
      ? previousRaw.trim()
      : String(current[typedField] ?? "").trim();
    const next = typeof currentRaw === "string" ? currentRaw.trim() : "";
    if (!previous || !next || previous === next) continue;
    out.push({ field: typedField, previous, current: next });
  }
  return out;
}

export function synthesizeDiffSummary(
  before: ThesisSnapshot,
  after: ThesisSnapshot,
  contradictions: ThesisContradiction[],
): string {
  const parts: string[] = [];
  for (const c of contradictions) {
    parts.push(`${c.field}: was "${c.previous}" → "${c.current}"`);
  }
  for (const key of THESIS_TEXT_FIELDS) {
    if (contradictionForField(contradictions, key)) continue;
    const prev = String(before[key] ?? "").trim();
    const next = String(after[key] ?? "").trim();
    if (prev === next) continue;
    if (!prev && next) {
      parts.push(`${key}: added`);
    } else if (prev && next) {
      parts.push(`${key}: updated`);
    }
  }
  return parts.join("; ");
}

export function ensureDiffKeepsContradiction(
  diffSummary: string | null | undefined,
  contradictions: ThesisContradiction[],
  before: ThesisSnapshot,
  after: ThesisSnapshot,
): string {
  let text = (diffSummary ?? "").trim();
  if (!text) {
    text = synthesizeDiffSummary(before, after, contradictions);
  }
  for (const c of contradictions) {
    const needle = c.previous.slice(0, Math.min(40, c.previous.length));
    if (needle && !text.includes(needle)) {
      const extra = `${c.field}: was "${c.previous}" → "${c.current}"`;
      text = text ? `${text}; ${extra}` : extra;
    }
  }
  return text;
}

export function fallbackConversationScript(
  evidence: Record<string, FieldEvidence>,
  followUps: string[],
): string {
  const unbacked = Object.entries(evidence)
    .filter(([, e]) => e.kind === "unbacked")
    .map(([key]) => key);
  const lines: string[] = [];
  if (unbacked.length > 0) {
    lines.push(`Test unbacked stakes: ${unbacked.join(", ")}.`);
  }
  for (const q of followUps.slice(0, 5)) {
    const trimmed = q.trim();
    if (trimmed) lines.push(`• ${trimmed}`);
  }
  if (lines.length === 0) {
    return "Talk to the next customer this week. Do not pitch — ask what they already tried and what they would pay to fix.";
  }
  return lines.join("\n");
}

export function nextRoundNumber(priorCount: number): number {
  return priorCount + 1;
}

export function weekWindowStart(now = new Date()): string {
  const start = new Date(now.getTime() - WEEK_WINDOW_DAYS * 24 * 60 * 60 * 1000);
  return start.toISOString();
}

export function mergeAppliedThesis(opts: {
  current: ThesisSnapshot;
  incoming: ApplyModelResponse;
  noteId: string;
  templateId?: string | null;
}): MergedThesisApply {
  const contradictions = normalizeContradictions(
    opts.incoming.contradictions,
    opts.current,
  );

  const merged: ThesisSnapshot = { ...opts.current };
  for (const key of THESIS_TEXT_FIELDS) {
    merged[key] = mergeTextField(
      opts.current[key],
      opts.incoming[key],
      contradictionForField(contradictions, key),
    );
  }

  const followUps = Array.isArray(opts.incoming.follow_up_questions)
    ? opts.incoming.follow_up_questions.filter((q) => !isBlank(q))
    : (opts.current.follow_up_questions ?? []);

  const incomingEvidence = normalizeFieldEvidence(
    opts.incoming.field_evidence,
    opts.noteId,
    opts.templateId,
  );
  const currentEvidence = opts.current.field_evidence ?? {};
  const field_evidence = stampEvidenceNoteId(
    { ...currentEvidence, ...incomingEvidence },
    opts.noteId,
  );

  for (const key of THESIS_TEXT_FIELDS) {
    if (isBlank(merged[key])) continue;
    if (field_evidence[key]) continue;
    field_evidence[key] = {
      kind: defaultEvidenceKind(opts.templateId, false),
      quote: null,
      note_id: opts.noteId,
    };
  }

  let next_conversation_script =
    typeof opts.incoming.next_conversation_script === "string"
      ? opts.incoming.next_conversation_script.trim()
      : "";
  if (!next_conversation_script) {
    next_conversation_script = fallbackConversationScript(
      field_evidence,
      followUps,
    );
  }

  merged.follow_up_questions = followUps;
  merged.next_conversation_script = next_conversation_script;
  merged.field_evidence = field_evidence;

  const diff_summary = ensureDiffKeepsContradiction(
    opts.incoming.diff_summary,
    contradictions,
    opts.current,
    merged,
  );

  return {
    snapshot: merged,
    contradictions,
    diff_summary,
    field_evidence,
    next_conversation_script,
    follow_up_questions: followUps,
  };
}

export const APPLY_SYSTEM_PROMPT =
  `You update a founder's living company thesis after a conversation debrief.

Your job is to APPEND and REFINE the current thesis, not rewrite it from scratch.

Rules:
- Keep existing field text unless the debrief clearly adds, confirms, or contradicts it.
- If the debrief contradicts a field: put the new version in that field AND list the change in "contradictions". Never silently overwrite.
- Write in the language of the transcription (English or Russian).
- Fill field_evidence for every populated thesis field. kind must be one of: founder_claim, customer_signal, unbacked.
  - customer_discovery debriefs: use customer_signal when the quote is a customer/user statement.
  - founder pitch or the founder's own words: founder_claim.
  - a stake with no quote or confirmation: unbacked.
- next_conversation_script: 3–5 short bullets — who to talk to next, what hypothesis to test, and what NOT to ask.
- follow_up_questions: 3 open questions from remaining unbacked stakes.
- diff_summary: one short paragraph of what changed. If there is a contradiction, mention the previous wording.

Return strictly JSON:
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
  "next_conversation_script": "",
  "field_evidence": {
    "problem": { "kind": "founder_claim", "quote": "" }
  },
  "contradictions": [
    { "field": "problem", "previous": "", "current": "" }
  ],
  "diff_summary": ""
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
  let prompt = "=== CURRENT THESIS ===\n";
  prompt += JSON.stringify(opts.thesis, null, 2);
  prompt += "\n\n";

  if (opts.analysis) {
    prompt += "=== NOTE-LEVEL ANALYSIS (event, not the living thesis) ===\n";
    prompt += JSON.stringify(opts.analysis, null, 2);
    prompt += "\n\n";
  }

  if (opts.weekDebriefs.length > 0) {
    prompt += "=== OTHER DEBRIEFS THIS WEEK ===\n";
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
    prompt += `=== DEBRIEF TEMPLATE ===\n${opts.templateId}\n\n`;
  }

  prompt += "=== DEBRIEF TRANSCRIPT ===\n";
  prompt += opts.transcription;
  return prompt;
}
