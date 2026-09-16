import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";
import {
  invokeApplyDebriefToThesis,
  linkNoteToUserThesis,
} from "../_shared/thesis_link.ts";
import { readMp4DurationSeconds } from "./mp4_duration.ts";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const TRANSCRIBE_MODEL = "gpt-4o-mini-transcribe";
const CHAT_MODEL = "gpt-4o-mini";

// Tier → monthly recording-time budget, in seconds.
// MUST stay in sync with kFreeMonthlyLimitSeconds / kBasicMonthlyLimitSeconds /
// kProMonthlyLimitSeconds in lib/core/constants/audio_notes_constants.dart.
const TIER_MONTHLY_LIMIT_SECONDS: Record<string, number> = {
  free: 300,
  basic: 1200,
  pro: 3600,
};

type AnalysisJson = {
  summary: string;
  startup_title: string;
  problem: string;
  solution: string;
  target_audience: string;
  business_model: string;
  key_metrics: string;
  advantages: string;
  risks_gaps: string;
  follow_up_questions: string[];
  market_potential_score: number;
  technical_complexity_score: number;
};

const ANALYSIS_JSON_SCHEMA = `{
  "summary": "",
  "startup_title": "",
  "problem": "",
  "solution": "",
  "target_audience": "",
  "business_model": "",
  "key_metrics": "",
  "advantages": "",
  "risks_gaps": "",
  "follow_up_questions": ["", ""],
  "market_potential_score": 0,
  "technical_complexity_score": 0
}`;

const ANALYSIS_JSON_RULES = `Rules:
- if data is missing, use "not specified" (except startup_title — see below)
- startup_title: a short, human-readable headline for this note (same language as the transcription, roughly 6–12 words). Describe the concrete idea or topic. Never use "not specified" here unless the transcription truly has no topic at all.
- follow_up_questions is always an array of strings (can be empty)
- market_potential_score — integer 0-100, market potential assessment
- technical_complexity_score — integer 0-100, technical complexity assessment
- no markdown, only JSON`;

const TEMPLATE_ANALYST_INTROS: Record<string, string> = {
  founder_pitch:
    "You are a startup business analyst reviewing a founder's spoken pitch memo.",
  customer_discovery:
    "You are a startup business analyst reviewing a customer discovery interview memo. Emphasize user pain, interview insights, segment clarity, and validation next steps. Map spoken content into the same structured fields (problem = user pain, solution = proposed value, target_audience = interview segment, key_metrics = signals or quotes, advantages = differentiated insight, risks_gaps = open questions).",
  investor_update:
    "You are a startup business analyst reviewing a founder's investor update memo. Emphasize progress, metrics, product changes, challenges, and the explicit ask. Map spoken content into the same structured fields (problem = context or market, solution = product progress, key_metrics = KPIs mentioned, risks_gaps = blockers, follow_up_questions = investor follow-ups).",
};

function normalizeTemplateId(raw: unknown): string {
  if (typeof raw !== "string") return "founder_pitch";
  const id = raw.trim();
  if (id in TEMPLATE_ANALYST_INTROS) return id;
  return "founder_pitch";
}

function buildAnalysisPrompt(templateId: string, transcriptText: string): string {
  const intro =
    TEMPLATE_ANALYST_INTROS[normalizeTemplateId(templateId)] ??
    TEMPLATE_ANALYST_INTROS.founder_pitch;

  return `${intro}

Based on the transcription, return strictly JSON with this structure:
${ANALYSIS_JSON_SCHEMA}

${ANALYSIS_JSON_RULES}

Transcription:
${transcriptText}`;
}

function extractTranscriptText(trJson: unknown): string {
  if (trJson && typeof trJson === "object" && "text" in trJson) {
    const t = (trJson as { text?: unknown }).text;
    if (typeof t === "string" && t.trim()) return t.trim();
  }
  return "";
}

const MAX_NOTE_TITLE_LENGTH = 200;
const NOT_SPECIFIED_RE = /^not\s*specified$/i;

/** Collapse whitespace and cap length for `audio_notes.title`. */
function clampNoteTitle(raw: string): string {
  const t = raw.replace(/\s+/g, " ").trim();
  if (!t) return "";
  if (t.length <= MAX_NOTE_TITLE_LENGTH) return t;
  return `${t.slice(0, MAX_NOTE_TITLE_LENGTH - 3).trimEnd()}...`;
}

/**
 * Prefer AI `startup_title`, then summary, then a short transcript snippet so
 * the list/detail headline matches the idea instead of the draft "Voice Note …".
 */
function deriveNoteTitle(
  parsed: AnalysisJson,
  transcriptText: string,
): string {
  const startup = (parsed.startup_title ?? "").trim();
  if (startup && !NOT_SPECIFIED_RE.test(startup)) {
    return clampNoteTitle(startup);
  }
  const summary = (parsed.summary ?? "").trim();
  if (summary && !NOT_SPECIFIED_RE.test(summary)) {
    return clampNoteTitle(summary);
  }
  const tr = transcriptText.replace(/\s+/g, " ").trim();
  if (tr) {
    return clampNoteTitle(tr.length > 140 ? `${tr.slice(0, 137)}...` : tr);
  }
  return "";
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const openaiKey = Deno.env.get("OPENAI_API_KEY");

  if (!supabaseUrl || !serviceKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    return jsonResponse({ error: "Server misconfiguration" }, 500);
  }
  if (!openaiKey) {
    console.error("Missing OPENAI_API_KEY");
    return jsonResponse({ error: "OpenAI is not configured" }, 500);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse({ error: "Missing authorization" }, 401);
  }
  const jwt = authHeader.slice("Bearer ".length).trim();

  let body: { audio_note_id?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const audioNoteId = body.audio_note_id;
  if (!audioNoteId || typeof audioNoteId !== "string") {
    return jsonResponse({ error: "audio_note_id is required" }, 400);
  }

  const supabase = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const {
    data: { user },
    error: authErr,
  } = await supabase.auth.getUser(jwt);
  if (authErr || !user) {
    return jsonResponse({ error: "Invalid or expired session" }, 401);
  }

  const { data: note, error: noteErr } = await supabase
    .from("audio_notes")
    .select("id, user_id, audio_path, status, duration_seconds, template_id")
    .eq("id", audioNoteId)
    .maybeSingle();

  if (noteErr || !note) {
    return jsonResponse({ error: "Note not found" }, 404);
  }
  if (note.user_id !== user.id) {
    return jsonResponse({ error: "Forbidden" }, 403);
  }

  // Ephemeral storage: once processing completes the raw audio is removed and
  // `audio_path` is nulled. A (re)processing request for such a note can never
  // succeed since there is no blob to transcribe, so reject it explicitly
  // instead of failing later at the download step.
  if (!note.audio_path) {
    return jsonResponse(
      {
        error: "Audio already processed and removed; nothing to reprocess.",
        code: "AUDIO_ALREADY_PROCESSED",
      },
      409,
    );
  }

  // ── Server-side usage gate ────────────────────────────────────────────
  // Mirrors the client-side check in `GetCurrentUsageUseCase`. Without it
  // the free tier limit is enforced only by the Flutter app and a curl
  // user (or one whose client state went stale) could bypass it. Logic:
  // "block if everything BUT this in-flight note already exceeds the
  // limit"; lets a final recording finish if the user was still under
  // quota when they started it.
  const { data: profile, error: profileErr } = await supabase
    .from("profiles")
    .select("subscription_tier")
    .eq("id", user.id)
    .maybeSingle();
  if (profileErr) {
    return jsonResponse({ error: "Could not verify subscription" }, 500);
  }
  const tier = (profile?.subscription_tier ?? "free") as string;
  const limitSeconds = TIER_MONTHLY_LIMIT_SECONDS[tier] ??
    TIER_MONTHLY_LIMIT_SECONDS.free;

  const now = new Date();
  const periodStart = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1),
  ).toISOString();
  const periodEnd = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1),
  ).toISOString();

  const { data: usageRows, error: usageErr } = await supabase
    .from("audio_notes")
    .select("duration_seconds")
    .eq("user_id", user.id)
    .neq("status", "failed")
    .neq("id", audioNoteId)
    .gte("created_at", periodStart)
    .lt("created_at", periodEnd);
  if (usageErr) {
    return jsonResponse({ error: "Could not verify usage" }, 500);
  }
  const previouslyUsed = (usageRows ?? []).reduce(
    (sum: number, row: { duration_seconds: number | null }) =>
      sum + (Number(row.duration_seconds) || 0),
    0,
  );
  if (previouslyUsed >= limitSeconds) {
    // Mark this note as failed so it stops cluttering the user's list as
    // "Uploaded — processing forever". The client can offer a delete or
    // upgrade flow on top of the error code.
    await supabase
      .from("audio_notes")
      .update({
        status: "failed",
        last_processing_error:
          "Monthly recording limit reached. Upgrade to continue.",
      })
      .eq("id", audioNoteId);
    return jsonResponse(
      {
        error: "Monthly recording limit reached. Upgrade to continue.",
        code: "USAGE_LIMIT_REACHED",
        tier,
        limit_seconds: limitSeconds,
        used_seconds: previouslyUsed,
      },
      429,
    );
  }

  try {
    const { error: stErr } = await supabase
      .from("audio_notes")
      .update({ status: "processing_transcription", last_processing_error: null })
      .eq("id", audioNoteId);
    if (stErr) throw new Error(stErr.message);

    const { data: fileData, error: dlErr } = await supabase.storage
      .from("audio-notes")
      .download(note.audio_path);
    if (dlErr || !fileData) {
      throw new Error(dlErr?.message ?? "Failed to download audio");
    }

    const ab = await fileData.arrayBuffer();
    const bytes = new Uint8Array(ab);

    // Whisper API rejects payloads above 25 MB with HTTP 413 and a
    // generic error blob. Pre-check here so the user sees a clear,
    // actionable message instead of "Request Entity Too Large" surfaced
    // from OpenAI.
    const MAX_WHISPER_BYTES = 25 * 1024 * 1024;
    if (bytes.byteLength > MAX_WHISPER_BYTES) {
      throw new Error(
        "Recording is too long for transcription. Please record a " +
          "shorter clip (under ~10 minutes / 25 MB).",
      );
    }

    // Server-authoritative recording length: read it from the audio container
    // instead of trusting the client-supplied `duration_seconds` that the
    // quota gate sums. A tampered client could otherwise send 0 to record for
    // free. Falls back to the client value only if the atom can't be parsed.
    const measuredDuration = readMp4DurationSeconds(bytes);
    if (
      measuredDuration != null && Number.isFinite(measuredDuration) &&
      measuredDuration >= 0
    ) {
      const clamped = Math.min(measuredDuration, 24 * 60 * 60);
      const { error: durErr } = await supabase
        .from("audio_notes")
        .update({ duration_seconds: clamped })
        .eq("id", audioNoteId);
      if (durErr) {
        console.error("duration_seconds override failed:", durErr.message);
      }
    } else {
      console.warn(
        `Could not measure audio duration server-side for note ${audioNoteId}; keeping client value`,
      );
    }

    const fileName = note.audio_path.split("/").pop() ?? "recording.m4a";

    const form = new FormData();
    const blob = new Blob([bytes], { type: "audio/m4a" });
    form.append("file", blob, fileName);
    form.append("model", TRANSCRIBE_MODEL);
    form.append("response_format", "json");

    const trRes = await fetch("https://api.openai.com/v1/audio/transcriptions", {
      method: "POST",
      headers: { Authorization: `Bearer ${openaiKey}` },
      body: form,
    });
    const trJson = (await trRes.json()) as {
      text?: string;
      error?: { message?: string };
    };
    if (!trRes.ok) {
      throw new Error(
        trJson.error?.message ?? `Transcription failed (${trRes.status})`,
      );
    }
    const transcriptText = extractTranscriptText(trJson);
    if (!transcriptText) {
      throw new Error(
        `Empty or unexpected transcription response: ${JSON.stringify(trJson).slice(0, 400)}`,
      );
    }

    const { error: upTrErr } = await supabase.from("audio_note_transcripts")
      .upsert(
        {
          audio_note_id: audioNoteId,
          user_id: note.user_id,
          transcript_text: transcriptText,
        },
        { onConflict: "audio_note_id" },
      );
    if (upTrErr) throw new Error(upTrErr.message);

    const { error: st2Err } = await supabase
      .from("audio_notes")
      .update({ status: "processing_analysis" })
      .eq("id", audioNoteId);
    if (st2Err) throw new Error(st2Err.message);

    const analysisPrompt = buildAnalysisPrompt(
      note.template_id,
      transcriptText,
    );

    const chatRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openaiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: CHAT_MODEL,
        messages: [{ role: "user", content: analysisPrompt }],
        response_format: { type: "json_object" },
        temperature: 0.3,
      }),
    });
    const chatJson = (await chatRes.json()) as {
      choices?: { message?: { content?: string } }[];
      error?: { message?: string };
    };
    if (!chatRes.ok) {
      throw new Error(
        chatJson.error?.message ?? `Chat completion failed (${chatRes.status})`,
      );
    }
    const rawContent = chatJson.choices?.[0]?.message?.content ?? "{}";
    let parsed: AnalysisJson;
    try {
      parsed = JSON.parse(rawContent) as AnalysisJson;
    } catch {
      throw new Error("AI returned invalid JSON");
    }

    const { error: upAnErr } = await supabase.from("startup_analyses").upsert(
      {
        audio_note_id: audioNoteId,
        user_id: note.user_id,
        short_summary: parsed.summary ?? "",
        startup_title: parsed.startup_title ?? "",
        problem: parsed.problem ?? "",
        solution: parsed.solution ?? "",
        target_audience: parsed.target_audience ?? "",
        business_model: parsed.business_model ?? "",
        key_metrics: parsed.key_metrics ?? "",
        advantages: parsed.advantages ?? "",
        risks_gaps: parsed.risks_gaps ?? "",
        follow_up_questions: parsed.follow_up_questions ?? [],
        market_potential_score: parsed.market_potential_score ?? 0,
        technical_complexity_score: parsed.technical_complexity_score ?? 0,
        raw_ai_response: parsed,
      },
      { onConflict: "audio_note_id" },
    );
    if (upAnErr) throw new Error(upAnErr.message);

    const listTitle = deriveNoteTitle(parsed, transcriptText);

    const { error: doneErr } = await supabase
      .from("audio_notes")
      .update({
        status: "completed",
        last_processing_error: null,
        ...(listTitle ? { title: listTitle } : {}),
      })
      .eq("id", audioNoteId);
    if (doneErr) throw new Error(doneErr.message);

    // Ephemeral storage: the bucket is a staging area for the processing
    // pipeline, not a media library. Once a note is completed the transcript
    // and analysis are the durable artifacts, so the raw audio blob is
    // deleted and `audio_path` is nulled. We remove the blob first and only
    // null the column on success — a transient removal failure therefore
    // leaves a recoverable reference for retry/cleanup instead of orphaning
    // the object forever.
    await cleanupAudioBlob(supabase, audioNoteId, note.audio_path);

    // Living thesis: attach this event to the account thesis, then apply the
    // debrief. Prompts above stay note-level; apply is a second step so it
    // can be rolled back without mixing analysis instructions.
    try {
      await linkNoteToUserThesis(supabase, note.user_id, audioNoteId);
    } catch (e) {
      console.error(
        "[process-audio-note] thesis_id attach failed:",
        e instanceof Error ? e.message : String(e),
      );
    }
    try {
      await invokeApplyDebriefToThesis({
        supabaseUrl,
        authorization: authHeader,
        apikey: serviceKey,
        noteId: audioNoteId,
      });
    } catch (e) {
      console.error(
        "[process-audio-note] apply-debrief-to-thesis invoke error:",
        e instanceof Error ? e.message : String(e),
      );
    }

    return jsonResponse({ ok: true, status: "completed" }, 200);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error("process-audio-note error:", msg);

    await supabase
      .from("audio_notes")
      .update({ status: "failed", last_processing_error: msg })
      .eq("id", audioNoteId);

    return jsonResponse({ error: msg }, 500);
  }
});

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/**
 * Best-effort removal of the staging audio blob after a note is completed.
 * Never throws — the note is already completed, so cleanup must not turn a
 * successful run into a failure. The `audio_path` column is only nulled once
 * the Storage object is actually gone, keeping the reference recoverable if
 * the remove call fails transiently.
 */
async function cleanupAudioBlob(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  audioNoteId: string,
  audioPath: string | null,
): Promise<void> {
  if (!audioPath) return;
  try {
    const { error: rmErr } = await supabase.storage
      .from("audio-notes")
      .remove([audioPath]);
    if (rmErr) {
      console.error("audio blob cleanup failed:", rmErr.message);
      return;
    }
    const { error: nullErr } = await supabase
      .from("audio_notes")
      .update({ audio_path: null })
      .eq("id", audioNoteId);
    if (nullErr) {
      console.error("audio_path null update failed:", nullErr.message);
    }
  } catch (e) {
    console.error(
      "audio blob cleanup error:",
      e instanceof Error ? e.message : String(e),
    );
  }
}
