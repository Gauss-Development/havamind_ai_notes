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
  hydrateThesisForApply,
  isApplyBlockedForTier,
  isNoteReadyToApply,
  mergeAppliedThesis,
  nextRoundNumber,
  parseNoteId,
  readBearerToken,
  snapshotFromThesisRow,
  weekWindowStart,
  type ApplyModelResponse,
  type NoteAnalysis,
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
  const parsedNote = parseNoteId(body);
  if (!parsedNote.ok) {
    return jsonResponse({ error: parsedNote.error }, parsedNote.status);
  }
  const { noteId } = parsedNote;

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

  // Free users may apply a debrief. Do not reuse refine-plan's 403.
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
        error: "Thesis apply is not available on this plan.",
        code: "UPGRADE_REQUIRED",
      },
      403,
    );
  }

  const { data: note, error: noteErr } = await supabase
    .from("audio_notes")
    .select("id, user_id, status, thesis_id, template_id, created_at, title")
    .eq("id", noteId)
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
    .eq("audio_note_id", noteId)
    .maybeSingle();
  if (trErr) {
    return jsonResponse({ error: "Failed to load transcript" }, 500);
  }
  const transcriptText = (transcriptRow?.transcript_text as string | undefined) ??
    "";
  const ready = isNoteReadyToApply(transcriptText);
  if (!ready.ok) {
    return jsonResponse(
      { error: ready.error, code: ready.code },
      ready.status,
    );
  }

  const { data: analysisRow } = await supabase
    .from("startup_analyses")
    .select(
      "startup_title, short_summary, problem, solution, target_audience, business_model, key_metrics, advantages, risks_gaps, follow_up_questions",
    )
    .eq("audio_note_id", noteId)
    .maybeSingle();
  const analysis = (analysisRow as NoteAnalysis | null) ?? null;

  let thesisId: string;
  try {
    thesisId = await linkNoteToUserThesis(supabase, user.id, noteId);
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

  const currentThesis = hydrateThesisForApply(
    snapshotFromThesisRow(thesisRow as Record<string, unknown>),
    analysis,
  );

  const { data: priorVersions, error: pvErr } = await supabase
    .from("thesis_versions")
    .select("round_number")
    .eq("thesis_id", thesisId)
    .order("round_number", { ascending: true });
  if (pvErr) {
    console.error("Failed to load thesis versions:", pvErr.message);
    return jsonResponse({ error: "Failed to load thesis history" }, 500);
  }
  const currentRound = nextRoundNumber(priorVersions?.length ?? 0);

  const weekDebriefs = await loadWeekDebriefs(
    supabase,
    user.id,
    noteId,
  );

  const userPrompt = buildApplyUserPrompt({
    thesis: currentThesis,
    transcription: transcriptText,
    analysis,
    weekDebriefs,
    templateId: (note.template_id as string | null) ?? null,
  });

  try {
    const chatRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openaiKey}`,
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

    const rawContent = chatJson.choices?.[0]?.message?.content ?? "{}";
    let incoming: Record<string, unknown>;
    try {
      incoming = JSON.parse(rawContent) as Record<string, unknown>;
    } catch {
      throw new Error("AI returned invalid JSON");
    }

    const merged = mergeAppliedThesis({
      current: currentThesis,
      incoming: incoming as ApplyModelResponse,
      noteId,
      templateId: (note.template_id as string | null) ?? null,
    });

    const promptTokens = chatJson.usage?.prompt_tokens ?? 0;
    const completionTokens = chatJson.usage?.completion_tokens ?? 0;
    console.log(
      `[apply-debrief-to-thesis] round=${currentRound} thesis=${thesisId} ` +
        `note=${noteId} prompt_tokens=${promptTokens} ` +
        `completion_tokens=${completionTokens} prompt_version=${PROMPT_VERSION}`,
    );

    const { error: pvInsertErr } = await supabase.from("thesis_versions").insert({
      thesis_id: thesisId,
      user_id: user.id,
      round_number: currentRound,
      thesis_snapshot: merged.snapshot,
      transcription: transcriptText,
      follow_up_questions: merged.follow_up_questions,
      diff_summary: merged.diff_summary,
    });
    if (pvInsertErr) throw new Error(pvInsertErr.message);

    const { error: updateErr } = await supabase
      .from("theses")
      .update({
        title: merged.snapshot.title,
        short_summary: merged.snapshot.short_summary,
        problem: merged.snapshot.problem,
        solution: merged.snapshot.solution,
        target_audience: merged.snapshot.target_audience,
        business_model: merged.snapshot.business_model,
        key_metrics: merged.snapshot.key_metrics,
        advantages: merged.snapshot.advantages,
        risks_gaps: merged.snapshot.risks_gaps,
        follow_up_questions: merged.follow_up_questions,
        next_conversation_script: merged.next_conversation_script,
        field_evidence: merged.field_evidence,
      })
      .eq("id", thesisId);
    if (updateErr) throw new Error(updateErr.message);

    return jsonResponse(
      {
        ok: true,
        thesis_id: thesisId,
        note_id: noteId,
        round: currentRound,
        updatedThesis: merged.snapshot,
        fieldEvidence: merged.field_evidence,
        nextConversationScript: merged.next_conversation_script,
        contradictions: merged.contradictions,
        diffSummary: merged.diff_summary,
      },
      200,
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error("apply-debrief-to-thesis error:", msg);
    return jsonResponse({ error: msg }, 500);
  }
});

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
