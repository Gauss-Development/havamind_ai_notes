import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ── Helpers ─────────────────────────────────────────────────────────

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

const PLAN_SNAPSHOT_FIELDS = [
  "short_summary",
  "startup_title",
  "problem",
  "solution",
  "target_audience",
  "business_model",
  "key_metrics",
  "advantages",
  "risks_gaps",
  "follow_up_questions",
  "market_potential_score",
  "technical_complexity_score",
] as const;

// ── Main handler ────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    return jsonResponse({ error: "Server misconfiguration" }, 500);
  }

  // ── Auth ────────────────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse({ error: "Missing authorization" }, 401);
  }
  const jwt = authHeader.slice("Bearer ".length).trim();

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

  const url = new URL(req.url);

  // ── GET: list or detail ─────────────────────────────────────────
  if (req.method === "GET") {
    const versionId = url.searchParams.get("id");
    const planId = url.searchParams.get("plan_id");

    if (versionId) {
      // Fetch single version
      const { data: version, error } = await supabase
        .from("plan_versions")
        .select("*")
        .eq("id", versionId)
        .eq("user_id", user.id)
        .maybeSingle();

      if (error) {
        console.error("Failed to fetch version:", error.message);
        return jsonResponse({ error: "Failed to fetch version" }, 500);
      }
      if (!version) {
        return jsonResponse({ error: "Version not found" }, 404);
      }

      return jsonResponse({ version }, 200);
    }

    if (planId) {
      // List all versions for a plan
      const { data: versions, error } = await supabase
        .from("plan_versions")
        .select("*")
        .eq("plan_id", planId)
        .eq("user_id", user.id)
        .order("round_number", { ascending: true });

      if (error) {
        console.error("Failed to list versions:", error.message);
        return jsonResponse({ error: "Failed to list versions" }, 500);
      }

      return jsonResponse({ versions: versions ?? [] }, 200);
    }

    return jsonResponse(
      { error: "Provide either ?plan_id=... or ?id=..." },
      400,
    );
  }

  // ── POST: restore ───────────────────────────────────────────────
  if (req.method === "POST") {
    // Accept params from query string OR JSON body
    let bodyParams: { action?: string; id?: string } = {};
    try {
      bodyParams = await req.json();
    } catch { /* no body is fine if query params provided */ }

    const action = url.searchParams.get("action") ?? bodyParams.action;
    const versionId = url.searchParams.get("id") ?? bodyParams.id;

    if (action !== "restore") {
      return jsonResponse({ error: "Unknown action" }, 400);
    }
    if (!versionId) {
      return jsonResponse({ error: "id is required for restore" }, 400);
    }

    // Load the version to restore
    const { data: version, error: vErr } = await supabase
      .from("plan_versions")
      .select("*")
      .eq("id", versionId)
      .maybeSingle();

    if (vErr) {
      console.error("Failed to load version:", vErr.message);
      return jsonResponse({ error: "Failed to load version" }, 500);
    }
    if (!version) {
      return jsonResponse({ error: "Version not found" }, 404);
    }
    if (version.user_id !== user.id) {
      return jsonResponse({ error: "Forbidden" }, 403);
    }

    // Get current max round_number for this plan
    const { data: maxRow, error: maxErr } = await supabase
      .from("plan_versions")
      .select("round_number")
      .eq("plan_id", version.plan_id)
      .order("round_number", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (maxErr) {
      console.error("Failed to get max round:", maxErr.message);
      return jsonResponse({ error: "Failed to determine round number" }, 500);
    }

    const newRound = (maxRow?.round_number ?? 0) + 1;
    const snapshot = version.plan_snapshot as Record<string, unknown>;

    // Insert new version row (restore = new row, never destroy history)
    const { error: insertErr } = await supabase
      .from("plan_versions")
      .insert({
        plan_id: version.plan_id,
        audio_note_id: version.audio_note_id,
        user_id: user.id,
        round_number: newRound,
        plan_snapshot: snapshot,
        transcription: `[Restored from round ${version.round_number}]`,
        follow_up_questions: version.follow_up_questions,
        diff_summary: `Restored from round ${version.round_number}`,
      });

    if (insertErr) {
      console.error("Failed to insert restored version:", insertErr.message);
      return jsonResponse({ error: insertErr.message }, 500);
    }

    // Update startup_analyses with the restored snapshot
    const updateFields: Record<string, unknown> = {};
    for (const field of PLAN_SNAPSHOT_FIELDS) {
      if (snapshot[field] !== undefined) {
        updateFields[field] = snapshot[field];
      }
    }

    if (Object.keys(updateFields).length > 0) {
      const { error: updateErr } = await supabase
        .from("startup_analyses")
        .update(updateFields)
        .eq("id", version.plan_id);

      if (updateErr) {
        console.error("Failed to update analysis:", updateErr.message);
        return jsonResponse({ error: updateErr.message }, 500);
      }
    }

    return jsonResponse(
      {
        ok: true,
        restoredFrom: version.round_number,
        newRound,
        plan: snapshot,
      },
      200,
    );
  }

  return jsonResponse({ error: "Method not allowed" }, 405);
});
