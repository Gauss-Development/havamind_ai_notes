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

const PROMPT_VERSION = "refine-v2";

const SUMMARIZATION_PROMPT = `You are a concise business context summarizer.

Given a series of refinement rounds for a startup plan, produce a compact summary that preserves:
- Key decisions made by the founder
- Directions explicitly rejected or changed
- User priorities and preferences expressed
- Critical facts added in each round

Do NOT include the current plan state (that's provided separately). Focus only on the CONVERSATION HISTORY — what the user said and what changed.

Output a single block of text, max 500 words. No JSON, no markdown — just plain text.`;

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
  context_summary: string | null;
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
 * Truncation-only fallback when LLM summarization fails or isn't needed.
 */
function truncateContext(rounds: PriorRound[]): PriorRound[] {
  const keepVerbatim = rounds.slice(-2);
  const toSummarize = rounds.slice(0, -2);

  if (toSummarize.length === 0) {
    return keepVerbatim.map((r) => ({
      ...r,
      transcription: r.transcription.slice(0, MAX_CONTEXT_CHARS / 2),
    }));
  }

  const summaryText = toSummarize
    .map((r) => {
      const diff = r.diff_summary ? ` → ${r.diff_summary}` : "";
      return `Round ${r.round_number}: ${r.transcription.slice(0, 200)}${diff}`;
    })
    .join("\n");

  const condensed: PriorRound = {
    round_number: 0,
    transcription: `[Summary of rounds 1-${toSummarize.length}]\n${summaryText}`,
    diff_summary: null,
    context_summary: null,
  };

  return [condensed, ...keepVerbatim];
}

/**
 * When prior rounds exceed the context budget, use LLM to summarize older
 * rounds into a "story so far" block. Reuses stored context_summary from
 * a prior round if available. Falls back to truncation on failure.
 *
 * Returns { rounds, contextSummary } where contextSummary is the generated
 * summary to store on the new plan_version row.
 */
async function summarizeContext(
  rounds: PriorRound[],
  openaiKey: string,
): Promise<{ rounds: PriorRound[]; contextSummary: string | null }> {
  if (rounds.length === 0) return { rounds, contextSummary: null };

  const totalChars = rounds.reduce(
    (sum, r) => sum + r.transcription.length + (r.diff_summary?.length ?? 0),
    0,
  );

  if (totalChars <= MAX_CONTEXT_CHARS) {
    return { rounds, contextSummary: null };
  }

  const keepVerbatim = rounds.slice(-2);
  const toSummarize = rounds.slice(0, -2);

  if (toSummarize.length === 0) {
    return { rounds: truncateContext(rounds), contextSummary: null };
  }

  // Check if the most recent round to be summarized already has a
  // stored context_summary — if so, we can extend it instead of
  // re-summarizing everything from scratch.
  const lastSummarized = [...toSummarize].reverse()
    .find((r) => r.context_summary);
  const existingSummary = lastSummarized?.context_summary ?? null;

  // Build the text for the summarization LLM call
  let roundsText: string;
  if (existingSummary) {
    // Only summarize rounds AFTER the one that has the stored summary
    const afterIdx = toSummarize.indexOf(lastSummarized!);
    const newRounds = toSummarize.slice(afterIdx + 1);
    if (newRounds.length === 0) {
      // Existing summary covers all rounds to summarize — reuse directly
      const condensed: PriorRound = {
        round_number: 0,
        transcription: `[Context summary]\n${existingSummary}`,
        diff_summary: null,
        context_summary: existingSummary,
      };
      return {
        rounds: [condensed, ...keepVerbatim],
        contextSummary: existingSummary,
      };
    }
    roundsText = `Previous summary:\n${existingSummary}\n\nNew rounds to integrate:\n`;
    roundsText += newRounds
      .map((r) => {
        const diff = r.diff_summary ? `\nChanges: ${r.diff_summary}` : "";
        return `Round ${r.round_number}:\nUser input: ${r.transcription}${diff}`;
      })
      .join("\n\n");
  } else {
    roundsText = toSummarize
      .map((r) => {
        const diff = r.diff_summary ? `\nChanges: ${r.diff_summary}` : "";
        return `Round ${r.round_number}:\nUser input: ${r.transcription}${diff}`;
      })
      .join("\n\n");
  }

  // Call GPT-4o-mini for summarization
  try {
    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openaiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: CHAT_MODEL,
        messages: [
          { role: "system", content: SUMMARIZATION_PROMPT },
          { role: "user", content: roundsText },
        ],
        temperature: 0.2,
        max_tokens: 600,
      }),
    });

    if (!res.ok) {
      throw new Error(`Summarization call failed (${res.status})`);
    }

    const json = (await res.json()) as {
      choices?: { message?: { content?: string } }[];
      usage?: { prompt_tokens?: number; completion_tokens?: number };
    };

    const summary = json.choices?.[0]?.message?.content?.trim() ?? "";
    const sumTokens = json.usage?.prompt_tokens ?? 0;
    console.log(
      `[refine-plan] context_summarization rounds=${toSummarize.length} ` +
        `summary_tokens=${sumTokens} summary_chars=${summary.length}`,
    );

    if (!summary) {
      throw new Error("Summarization returned empty text");
    }

    const condensed: PriorRound = {
      round_number: 0,
      transcription: `[Context summary]\n${summary}`,
      diff_summary: null,
      context_summary: summary,
    };

    return {
      rounds: [condensed, ...keepVerbatim],
      contextSummary: summary,
    };
  } catch (e) {
    // Graceful fallback to truncation
    console.error(
      "[refine-plan] Summarization failed, falling back to truncation:",
      e instanceof Error ? e.message : String(e),
    );
    return { rounds: truncateContext(rounds), contextSummary: null };
  }
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
    followUpQuestionText?: string;
  };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const { planId, followUpQuestionId, followUpQuestionText } = body;
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
    .select("round_number, transcription, diff_summary, context_summary")
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
  // Prefer the client-snapshotted text (stable across AI rewrites of the
  // questions array between tap and submit). Fall back to the index for
  // older clients that didn't yet send the text.
  let followUpQuestion: string | null = null;
  if (followUpQuestionText && followUpQuestionText.trim().length > 0) {
    followUpQuestion = followUpQuestionText.trim();
  } else if (followUpQuestionId && analysis.follow_up_questions) {
    const questions = analysis.follow_up_questions as string[];
    const idx = parseInt(followUpQuestionId, 10);
    if (!isNaN(idx) && idx >= 0 && idx < questions.length) {
      followUpQuestion = questions[idx];
    }
  }

  // ── Build prompt with context management ────────────────────────
  const currentPlan = snapshotFromAnalysis(analysis);
  const { rounds: contextRounds, contextSummary } = await summarizeContext(
    priorVersions ?? [],
    openaiKey,
  );

  const userPrompt = buildRefinementUserPrompt(
    currentPlan,
    transcription,
    contextRounds,
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
      context_summary: contextSummary,
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
