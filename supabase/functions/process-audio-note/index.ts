import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const TRANSCRIBE_MODEL = "gpt-4o-mini-transcribe";
const CHAT_MODEL = "gpt-4o-mini";

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

function extractTranscriptText(trJson: unknown): string {
  if (trJson && typeof trJson === "object" && "text" in trJson) {
    const t = (trJson as { text?: unknown }).text;
    if (typeof t === "string" && t.trim()) return t.trim();
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
    .select("id, user_id, audio_path, status")
    .eq("id", audioNoteId)
    .maybeSingle();

  if (noteErr || !note) {
    return jsonResponse({ error: "Note not found" }, 404);
  }
  if (note.user_id !== user.id) {
    return jsonResponse({ error: "Forbidden" }, 403);
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

    const analysisPrompt =
      `You are a startup business analyst.

Based on the transcription, return strictly JSON with this structure:
{
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
}

Rules:
- if data is missing, use "not specified"
- follow_up_questions is always an array of strings (can be empty)
- market_potential_score — integer 0-100, market potential assessment
- technical_complexity_score — integer 0-100, technical complexity assessment
- no markdown, only JSON

Transcription:
${transcriptText}`;

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

    const { error: doneErr } = await supabase
      .from("audio_notes")
      .update({ status: "completed", last_processing_error: null })
      .eq("id", audioNoteId);
    if (doneErr) throw new Error(doneErr.message);

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
