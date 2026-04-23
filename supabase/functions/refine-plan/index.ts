import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const WHISPER_MODEL = "gpt-4o-mini-transcribe";
const CHAT_MODEL = "gpt-4o-mini";
const MAX_REFINEMENT_ROUNDS = 5;
const CONTEXT_TOKEN_BUDGET = 8000;
// Rough estimate: 1 token ≈ 4 chars for English, ~2 chars for Russian.
// Use conservative 3 chars/token to stay within budget.
const CHARS_PER_TOKEN = 3;
const MAX_CONTEXT_CHARS = CONTEXT_TOKEN_BUDGET * CHARS_PER_TOKEN;

// ── Prompt templates (versioned) ────────────────────────────────────
// Bump PROMPT_VERSION when changing prompt logic so we can correlate
// outputs to the prompt that generated them.

const PROMPT_VERSION = "refine-v1";

const REFINEMENT_SYSTEM_PROMPT = `Ты бизнес-аналитик стартапов. Тебе дан текущий план стартапа и новый голосовой ввод от основателя.

Твоя задача — ДОПОЛНИТЬ и УТОЧНИТЬ существующий план, а не переписывать его с нуля.

Правила:
- Сохрани всё, что уже есть в плане, если пользователь явно не отказался от этого
- Добавь новую информацию из голосового ввода в соответствующие секции
- Если новый ввод противоречит старому — используй новую версию и отметь изменение
- Если пользователь отвечает на конкретный follow-up вопрос, интегрируй ответ в план
- Генерируй новые follow-up вопросы на основе того, что ещё не раскрыто

Ответ верни строго в JSON:
{
  "short_summary": "",
  "startup_title": "",
  "problem": "",
  "solution": "",
  "target_audience": "",
  "business_model": "",
  "key_metrics": "",
  "advantages": "",
  "risks_gaps": "",
  "follow_up_questions": ["вопрос1", "вопрос2", "вопрос3"],
  "market_potential_score": 0,
  "technical_complexity_score": 0,
  "diff_summary": "Краткое описание что изменилось в этом раунде"
}`;

function buildRefinementUserPrompt(
  currentPlan: PlanSnapshot,
  transcription: string,
  priorRounds: PriorRound[],
  followUpQuestion: string | null,
): string {
  let prompt = "";

  // Context from prior rounds (if any, already summarized if needed)
  if (priorRounds.length > 0) {
    prompt += "=== ИСТОРИЯ УТОЧНЕНИЙ ===\n";
    for (const round of priorRounds) {
      prompt += `\nРаунд ${round.round_number}:\n`;
      prompt += `Ввод: ${round.transcription}\n`;
      if (round.diff_summary) {
        prompt += `Изменения: ${round.diff_summary}\n`;
      }
    }
    prompt += "\n";
  }

  prompt += "=== ТЕКУЩИЙ ПЛАН ===\n";
  prompt += JSON.stringify(currentPlan, null, 2);
  prompt += "\n\n";

  if (followUpQuestion) {
    prompt += `=== ВОПРОС, НА КОТОРЫЙ ОТВЕЧАЕТ ПОЛЬЗОВАТЕЛЬ ===\n`;
    prompt += `${followUpQuestion}\n\n`;
  }

  prompt += "=== НОВЫЙ ГОЛОСОВОЙ ВВОД ===\n";
  prompt += transcription;

  return prompt;
}

// ── Types ───────────────────────────────────────────────────────────

type PlanSnapshot = {
  short_summary?: string;
  startup_title?: string;
  problem?: string;
  solution?: string;
  target_audience?: string;
  business_model?: string;
  key_metrics?: string;
  advantages?: string;
  risks_gaps?: string;
  follow_up_questions?: string[];
  market_potential_score?: number;
  technical_complexity_score?: number;
};

type PriorRound = {
  round_number: number;
  transcription: string;
  diff_summary: string | null;
};

type RefinementResponse = {
  short_summary: string;
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
  diff_summary: string;
};

// ── Helpers ─────────────────────────────────────────────────────────

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function snapshotFromAnalysis(
  a: Record<string, unknown>,
): PlanSnapshot {
  return {
    short_summary: a.short_summary as string | undefined,
    startup_title: a.startup_title as string | undefined,
    problem: a.problem as string | undefined,
    solution: a.solution as string | undefined,
    target_audience: a.target_audience as string | undefined,
    business_model: a.business_model as string | undefined,
    key_metrics: a.key_metrics as string | undefined,
    advantages: a.advantages as string | undefined,
    risks_gaps: a.risks_gaps as string | undefined,
    follow_up_questions: a.follow_up_questions as string[] | undefined,
    market_potential_score: a.market_potential_score as number | undefined,
    technical_complexity_score: a.technical_complexity_score as
      | number
      | undefined,
  };
}

/**
 * When prior rounds exceed the context budget, summarize older rounds
 * into a single "story so far" block, keeping the most recent 2 rounds verbatim.
 */
function trimContext(
  rounds: PriorRound[],
): PriorRound[] {
  if (rounds.length === 0) return rounds;

  const totalChars = rounds.reduce(
    (sum, r) => sum + r.transcription.length + (r.diff_summary?.length ?? 0),
    0,
  );

  if (totalChars <= MAX_CONTEXT_CHARS) return rounds;

  // Keep last 2 rounds verbatim, summarize the rest
  const keepVerbatim = rounds.slice(-2);
  const toSummarize = rounds.slice(0, -2);

  if (toSummarize.length === 0) {
    // Only 2 rounds but still over budget — truncate transcriptions
    return keepVerbatim.map((r) => ({
      ...r,
      transcription: r.transcription.slice(0, MAX_CONTEXT_CHARS / 2),
    }));
  }

  const summaryText = toSummarize
    .map((r) => {
      const diff = r.diff_summary ? ` → ${r.diff_summary}` : "";
      return `Раунд ${r.round_number}: ${r.transcription.slice(0, 200)}${diff}`;
    })
    .join("\n");

  const condensed: PriorRound = {
    round_number: 0, // marker for "summary block"
    transcription: `[Сводка раундов 1-${toSummarize.length}]\n${summaryText}`,
    diff_summary: null,
  };

  return [condensed, ...keepVerbatim];
}

// ── Main handler ────────────────────────────────────────────────────

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

  // ── Auth ────────────────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse({ error: "Missing authorization" }, 401);
  }
  const jwt = authHeader.slice("Bearer ".length).trim();

  // ── Parse body ──────────────────────────────────────────────────
  let body: {
    planId?: string;
    transcription?: string;
    audioPath?: string;
    followUpQuestionId?: string;
  };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const { planId, followUpQuestionId } = body;
  let { transcription } = body;
  const { audioPath } = body;

  if (!planId || typeof planId !== "string") {
    return jsonResponse({ error: "planId is required" }, 400);
  }
  if (!transcription && !audioPath) {
    return jsonResponse({ error: "transcription or audioPath is required" }, 400);
  }

  const supabase = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // ── Verify JWT ──────────────────────────────────────────────────
  const {
    data: { user },
    error: authErr,
  } = await supabase.auth.getUser(jwt);
  if (authErr || !user) {
    return jsonResponse({ error: "Invalid or expired session" }, 401);
  }

  // ── Tier check ──────────────────────────────────────────────────
  const { data: profile, error: profileErr } = await supabase
    .from("profiles")
    .select("subscription_tier")
    .eq("id", user.id)
    .maybeSingle();

  if (profileErr || !profile) {
    return jsonResponse({ error: "Could not verify subscription" }, 500);
  }
  if (profile.subscription_tier === "free") {
    return jsonResponse(
      {
        error: "Plan refinement is available on paid plans. Upgrade to continue.",
        code: "UPGRADE_REQUIRED",
      },
      403,
    );
  }

  // ── Transcribe audio if audioPath provided ─────────────────────
  if (!transcription && audioPath) {
    const { data: audioData, error: dlErr } = await supabase.storage
      .from("audio-notes")
      .download(audioPath);
    if (dlErr || !audioData) {
      return jsonResponse({ error: "Failed to download audio file" }, 500);
    }

    const formData = new FormData();
    formData.append(
      "file",
      new Blob([audioData], { type: "audio/m4a" }),
      "audio.m4a",
    );
    formData.append("model", WHISPER_MODEL);

    const whisperRes = await fetch(
      "https://api.openai.com/v1/audio/transcriptions",
      {
        method: "POST",
        headers: { Authorization: `Bearer ${openaiKey}` },
        body: formData,
      },
    );
    if (!whisperRes.ok) {
      const err = await whisperRes.text();
      console.error("Whisper transcription failed:", err);
      return jsonResponse({ error: "Audio transcription failed" }, 500);
    }
    const whisperJson = (await whisperRes.json()) as { text?: string };
    transcription = whisperJson.text ?? "";
    if (transcription.trim().length === 0) {
      return jsonResponse({ error: "Transcription produced empty text" }, 400);
    }
  }

  if (!transcription || transcription.trim().length === 0) {
    return jsonResponse({ error: "transcription cannot be empty" }, 400);
  }

  // ── Load current plan (startup_analyses) ────────────────────────
  // planId maps to audio_note_id
  const { data: analysis, error: analysisErr } = await supabase
    .from("startup_analyses")
    .select("*")
    .eq("audio_note_id", planId)
    .maybeSingle();

  if (analysisErr || !analysis) {
    return jsonResponse({ error: "Plan not found" }, 404);
  }
  if (analysis.user_id !== user.id) {
    return jsonResponse({ error: "Forbidden" }, 403);
  }

  // ── Load prior refinement rounds ────────────────────────────────
  const { data: priorVersions, error: pvErr } = await supabase
    .from("plan_versions")
    .select("round_number, transcription, diff_summary")
    .eq("plan_id", analysis.id)
    .order("round_number", { ascending: true });

  if (pvErr) {
    console.error("Failed to load plan versions:", pvErr.message);
    return jsonResponse({ error: "Failed to load plan history" }, 500);
  }

  const currentRound = (priorVersions?.length ?? 0) + 1;

  // ── Enforce round cap ──────────────────────────────────────────
  if (currentRound > MAX_REFINEMENT_ROUNDS) {
    return jsonResponse(
      {
        error: `Maximum ${MAX_REFINEMENT_ROUNDS} refinement rounds reached for this plan.`,
        code: "MAX_ROUNDS_REACHED",
      },
      400,
    );
  }

  // ── Resolve follow-up question text ─────────────────────────────
  let followUpQuestion: string | null = null;
  if (followUpQuestionId && analysis.follow_up_questions) {
    const questions = analysis.follow_up_questions as string[];
    const idx = parseInt(followUpQuestionId, 10);
    if (!isNaN(idx) && idx >= 0 && idx < questions.length) {
      followUpQuestion = questions[idx];
    }
  }

  // ── Build prompt with context management ────────────────────────
  const currentPlan = snapshotFromAnalysis(analysis);
  const trimmedRounds = trimContext(priorVersions ?? []);

  const userPrompt = buildRefinementUserPrompt(
    currentPlan,
    transcription,
    trimmedRounds,
    followUpQuestion,
  );

  const inputTokenEstimate = Math.ceil(
    (REFINEMENT_SYSTEM_PROMPT.length + userPrompt.length) / CHARS_PER_TOKEN,
  );

  try {
    // ── Call GPT-4o-mini ─────────────────────────────────────────
    const chatRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openaiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: CHAT_MODEL,
        messages: [
          { role: "system", content: REFINEMENT_SYSTEM_PROMPT },
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
    let refined: RefinementResponse;
    try {
      refined = JSON.parse(rawContent) as RefinementResponse;
    } catch {
      throw new Error("AI returned invalid JSON");
    }

    // ── Telemetry: log token counts ──────────────────────────────
    const promptTokens = chatJson.usage?.prompt_tokens ?? inputTokenEstimate;
    const completionTokens = chatJson.usage?.completion_tokens ?? 0;
    console.log(
      `[refine-plan] round=${currentRound} plan=${analysis.id} ` +
        `prompt_tokens=${promptTokens} completion_tokens=${completionTokens} ` +
        `prompt_version=${PROMPT_VERSION}`,
    );

    // ── Write plan_version row ───────────────────────────────────
    const planSnapshot = snapshotFromAnalysis(refined as unknown as Record<string, unknown>);

    const { error: pvInsertErr } = await supabase.from("plan_versions").insert({
      plan_id: analysis.id,
      audio_note_id: planId,
      user_id: user.id,
      round_number: currentRound,
      plan_snapshot: planSnapshot,
      transcription: transcription,
      follow_up_questions: refined.follow_up_questions ?? [],
      diff_summary: refined.diff_summary ?? null,
      context_summary: null, // populated by GAU-96 when summarization kicks in
      follow_up_question_id: followUpQuestionId ?? null,
    });

    if (pvInsertErr) throw new Error(pvInsertErr.message);

    // ── Ensure an active refinement session exists ───────────────
    const { data: activeSession } = await supabase
      .from("plan_refinement_sessions")
      .select("id")
      .eq("plan_id", analysis.id)
      .eq("user_id", user.id)
      .is("finalized_at", null)
      .maybeSingle();

    if (!activeSession) {
      const { error: sessionErr } = await supabase
        .from("plan_refinement_sessions")
        .insert({
          plan_id: analysis.id,
          user_id: user.id,
        });
      if (sessionErr) {
        console.error("Failed to create refinement session:", sessionErr.message);
        // Non-fatal: don't block the refinement over a session tracking failure
      }
    }

    // ── Update startup_analyses with merged result ────────────────
    const { error: updateErr } = await supabase
      .from("startup_analyses")
      .update({
        short_summary: refined.short_summary ?? analysis.short_summary,
        startup_title: refined.startup_title ?? analysis.startup_title,
        problem: refined.problem ?? analysis.problem,
        solution: refined.solution ?? analysis.solution,
        target_audience: refined.target_audience ?? analysis.target_audience,
        business_model: refined.business_model ?? analysis.business_model,
        key_metrics: refined.key_metrics ?? analysis.key_metrics,
        advantages: refined.advantages ?? analysis.advantages,
        risks_gaps: refined.risks_gaps ?? analysis.risks_gaps,
        follow_up_questions: refined.follow_up_questions ?? analysis.follow_up_questions,
        market_potential_score: refined.market_potential_score ?? analysis.market_potential_score,
        technical_complexity_score:
          refined.technical_complexity_score ?? analysis.technical_complexity_score,
        raw_ai_response: refined,
      })
      .eq("id", analysis.id);

    if (updateErr) throw new Error(updateErr.message);

    // ── Return result ────────────────────────────────────────────
    return jsonResponse(
      {
        ok: true,
        round: currentRound,
        updatedPlan: planSnapshot,
        newFollowUpQuestions: refined.follow_up_questions ?? [],
        diffSummary: refined.diff_summary ?? "",
      },
      200,
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error("refine-plan error:", msg);
    return jsonResponse({ error: msg }, 500);
  }
});
