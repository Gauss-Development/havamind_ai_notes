import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

import { linkNoteToUserThesis } from "../_shared/thesis_link.ts";
import {
  APPLY_SYSTEM_PROMPT,
  CHAT_MODEL,
  PROMPT_VERSION,
  WEEK_DEBRIEF_LIMIT,
  assertNoteOwnership,
  buildApplyUserPrompt,
  executeConceptRewrite,
  isApplyBlockedForTier,
  isNoteReadyToApply,
  maxRoundNumber,
  modelCallRequired,
  parseApplyBody,
  parseModelJson,
  readBearerToken,
  rewriteGate,
  snapshotFromThesisRow,
  weekWindowStart,
  type ConceptDb,
  type NoteAnalysis,
  type ThesisUpdate,
  type VersionInsert,
  type WeekDebrief,
} from "./apply_logic.ts";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
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

  const auth = readBearerToken(req.headers.get("Authorization"));
  if (!auth.ok) {
    return jsonResponse({ error: auth.error }, auth.status);
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }
  const parsedBody = parseApplyBody(body);
  if (!parsedBody.ok) {
    return jsonResponse({ error: parsedBody.error }, parsedBody.status);
  }
  const request = parsedBody.value;
  const gate = rewriteGate({
    heardByLabel: request.heardByLabel,
    rewriteUnheard: request.rewriteUnheard,
  });

  const supabase = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const {
    data: { user },
    error: authErr,
  } = await supabase.auth.getUser(auth.jwt);
  if (authErr || !user) {
    return jsonResponse({ error: "Invalid or expired session" }, 401);
  }

  // Free users may rewrite a concept. Do not reuse refine-plan's 403.
  const { data: profile, error: profileErr } = await supabase
    .from("profiles")
    .select("subscription_tier")
    .eq("id", user.id)
    .maybeSingle();
  if (profileErr) {
    return jsonResponse({ error: "Could not verify subscription" }, 500);
  }
  const tier = (profile?.subscription_tier ?? "free") as string;
  if (isApplyBlockedForTier(tier)) {
    return jsonResponse(
      {
        error: "Concept rewrite is not available on this plan.",
        code: "UPGRADE_REQUIRED",
      },
      403,
    );
  }

  const { data: note, error: noteErr } = await supabase
    .from("audio_notes")
    .select("id, user_id, status, thesis_id, template_id, created_at, title")
    .eq("id", request.noteId)
    .maybeSingle();

  if (noteErr || !note) {
    return jsonResponse({ error: "Note not found" }, 404);
  }
  const owned = assertNoteOwnership(note.user_id as string, user.id);
  if (!owned.ok) {
    return jsonResponse({ error: owned.error }, owned.status);
  }

  const { data: transcriptRow, error: trErr } = await supabase
    .from("audio_note_transcripts")
    .select("transcript_text")
    .eq("audio_note_id", request.noteId)
    .maybeSingle();
  if (trErr) {
    return jsonResponse({ error: "Failed to load transcript" }, 500);
  }
  const transcriptText = (transcriptRow?.transcript_text as string | undefined) ??
    "";
  const ready = isNoteReadyToApply(transcriptText);
  if (!ready.ok) {
    return jsonResponse({ error: ready.error, code: ready.code }, ready.status);
  }

  const { data: analysisRow } = await supabase
    .from("startup_analyses")
    .select(
      "startup_title, short_summary, problem, solution, target_audience, business_model, key_metrics, advantages, risks_gaps, follow_up_questions",
    )
    .eq("audio_note_id", request.noteId)
    .maybeSingle();
  const analysis = (analysisRow as NoteAnalysis | null) ?? null;

  let thesisId: string;
  try {
    thesisId = await linkNoteToUserThesis(supabase, user.id, request.noteId);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error("[apply-debrief-to-thesis] thesis attach failed:", msg);
    return jsonResponse({ error: "Failed to attach note to thesis" }, 500);
  }

  const { data: thesisRow, error: thesisErr } = await supabase
    .from("theses")
    .select("*")
    .eq("id", thesisId)
    .maybeSingle();
  if (thesisErr || !thesisRow) {
    return jsonResponse({ error: "Thesis not found" }, 500);
  }

  const currentThesis = snapshotFromThesisRow(
    thesisRow as Record<string, unknown>,
  );

  const { data: priorVersions, error: pvErr } = await supabase
    .from("thesis_versions")
    .select("round_number")
    .eq("thesis_id", thesisId);
  if (pvErr) {
    console.error("Failed to load thesis versions:", pvErr.message);
    return jsonResponse({ error: "Failed to load thesis history" }, 500);
  }

  const needsModel = modelCallRequired({
    gate,
    proposedRewrite: request.proposedRewrite,
  });
  let modelJson: Record<string, unknown> | null = null;
  if (needsModel) {
    try {
      const weekDebriefs = await loadWeekDebriefs(
        supabase,
        user.id,
        request.noteId,
      );
      modelJson = await requestConceptRewrite({
        openaiKey,
        thesis: currentThesis,
        transcription: transcriptText,
        analysis,
        weekDebriefs,
        templateId: (note.template_id as string | null) ?? null,
      });
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      console.error("apply-debrief-to-thesis model error:", msg);
      return jsonResponse({ error: msg }, 500);
    }
  }

  const db: ConceptDb = {
    insertVersion: (row) => insertVersion(supabase, row),
    updateThesis: (id, patch) => updateThesis(supabase, id, patch),
  };

  try {
    const result = await executeConceptRewrite({
      gate,
      current: currentThesis,
      modelJson,
      proposedRewrite: request.proposedRewrite,
      thesisId,
      userId: user.id,
      noteId: request.noteId,
      templateId: (note.template_id as string | null) ?? null,
      transcription: transcriptText,
      priorMaxRound: maxRoundNumber(priorVersions),
      debriefCount: Number(
        (thesisRow as { debrief_count?: number }).debrief_count ?? 0,
      ),
      heardAt: new Date().toISOString(),
      db,
    });

    if (!result.written) {
      return jsonResponse(
        {
          error: result.error ?? "Concept was not rewritten",
          ...(result.code ? { code: result.code } : {}),
          ...(result.suggestedHearer
            ? { suggested_hearer: result.suggestedHearer }
            : {}),
          ...(result.proposedRewrite
            ? { proposed_rewrite: result.proposedRewrite }
            : {}),
        },
        result.status,
      );
    }

    console.log(
      `[apply-debrief-to-thesis] thesis=${thesisId} note=${request.noteId} ` +
        `heard_round=${result.heardRound ?? "-"} unheard_round=${result.unheardRound} ` +
        `prompt_version=${PROMPT_VERSION}`,
    );

    return jsonResponse(
      {
        ok: true,
        thesis_id: thesisId,
        note_id: request.noteId,
        round: result.unheardRound,
        heard_round: result.heardRound,
        debrief_count: result.debriefCount,
        updatedThesis: result.updatedThesis,
        rewriteNote: result.rewriteNote,
      },
      200,
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error("apply-debrief-to-thesis error:", msg);
    return jsonResponse({ error: msg }, 500);
  }
});

async function requestConceptRewrite(opts: {
  openaiKey: string;
  thesis: ReturnType<typeof snapshotFromThesisRow>;
  transcription: string;
  analysis: NoteAnalysis | null;
  weekDebriefs: WeekDebrief[];
  templateId: string | null;
}): Promise<Record<string, unknown>> {
  const userPrompt = buildApplyUserPrompt({
    thesis: opts.thesis,
    transcription: opts.transcription,
    analysis: opts.analysis,
    weekDebriefs: opts.weekDebriefs,
    templateId: opts.templateId,
  });
  const chatRes = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${opts.openaiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: CHAT_MODEL,
      messages: [
        { role: "system", content: APPLY_SYSTEM_PROMPT },
        { role: "user", content: userPrompt },
      ],
      response_format: { type: "json_object" },
      temperature: 0.3,
    }),
  });

  const chatJson = (await chatRes.json()) as {
    choices?: { message?: { content?: string } }[];
    usage?: { prompt_tokens?: number; completion_tokens?: number };
    error?: { message?: string };
  };
  if (!chatRes.ok) {
    throw new Error(
      chatJson.error?.message ?? `Chat completion failed (${chatRes.status})`,
    );
  }
  const parsed = parseModelJson(chatJson.choices?.[0]?.message?.content ?? "{}");
  if (!parsed.ok) throw new Error(parsed.error);
  const promptTokens = chatJson.usage?.prompt_tokens ?? 0;
  const completionTokens = chatJson.usage?.completion_tokens ?? 0;
  console.log(
    `[apply-debrief-to-thesis] model prompt_tokens=${promptTokens} ` +
      `completion_tokens=${completionTokens} prompt_version=${PROMPT_VERSION}`,
  );
  return parsed.value;
}

// deno-lint-ignore no-explicit-any
async function insertVersion(supabase: any, row: VersionInsert) {
  const { error } = await supabase.from("thesis_versions").insert({
    thesis_id: row.thesis_id,
    user_id: row.user_id,
    round_number: row.round_number,
    thesis_snapshot: row.thesis_snapshot,
    transcription: row.transcription,
    diff_summary: row.diff_summary,
    follow_up_questions: row.follow_up_questions,
    source_note_id: row.source_note_id,
    source_template_id: row.source_template_id,
    hearing_status: row.hearing_status,
    heard_by_label: row.heard_by_label,
    heard_at: row.heard_at,
  });
  return { error: error?.message ?? null };
}

// deno-lint-ignore no-explicit-any
async function updateThesis(supabase: any, thesisId: string, patch: ThesisUpdate) {
  const { error } = await supabase
    .from("theses")
    .update(patch)
    .eq("id", thesisId);
  return { error: error?.message ?? null };
}

// deno-lint-ignore no-explicit-any
async function loadWeekDebriefs(
  supabase: any,
  userId: string,
  currentNoteId: string,
): Promise<WeekDebrief[]> {
  const { data: notes, error } = await supabase
    .from("audio_notes")
    .select("id, title, template_id, created_at")
    .eq("user_id", userId)
    .eq("status", "completed")
    .neq("id", currentNoteId)
    .gte("created_at", weekWindowStart())
    .order("created_at", { ascending: false })
    .limit(WEEK_DEBRIEF_LIMIT);

  if (error || !notes?.length) {
    if (error) {
      console.error("Failed to load week debriefs:", error.message);
    }
    return [];
  }

  const ids = (notes as { id: string }[]).map((n) => n.id);
  const { data: transcripts } = await supabase
    .from("audio_note_transcripts")
    .select("audio_note_id, transcript_text")
    .in("audio_note_id", ids);

  const byNote = new Map<string, string>();
  for (const row of transcripts ?? []) {
    byNote.set(
      row.audio_note_id as string,
      (row.transcript_text as string) ?? "",
    );
  }

  return (notes as {
    id: string;
    title?: string | null;
    template_id?: string | null;
    created_at?: string | null;
  }[]).map((n) => ({
    note_id: n.id,
    title: n.title ?? null,
    template_id: n.template_id ?? null,
    created_at: n.created_at ?? null,
    transcript: byNote.get(n.id) ?? null,
  }));
}
