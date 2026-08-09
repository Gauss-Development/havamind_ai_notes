import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

// In-app account deletion (App Store Guideline 5.1.1(v) / Google Play).
// Validates the caller's JWT, removes their audio blobs from Storage (which is
// NOT cascade-deleted), then deletes the auth user. Every app table references
// auth.users(id) ON DELETE CASCADE, so profiles, notes, transcripts, analyses,
// tags and plan versions are removed with the user.

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const AUDIO_BUCKET = "audio-notes";

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** Recursively list every object under a Storage prefix. */
async function listAllFiles(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  bucket: string,
  prefix: string,
): Promise<string[]> {
  const files: string[] = [];
  const { data, error } = await supabase.storage
    .from(bucket)
    .list(prefix, { limit: 1000 });
  if (error || !data) return files;
  for (const entry of data) {
    const path = prefix ? `${prefix}/${entry.name}` : entry.name;
    // Folders come back with a null id in Supabase Storage listings.
    if (entry.id === null) {
      files.push(...(await listAllFiles(supabase, bucket, path)));
    } else {
      files.push(path);
    }
  }
  return files;
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
  if (!supabaseUrl || !serviceKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    return jsonResponse({ error: "Server misconfiguration" }, 500);
  }

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

  // 1. Best-effort removal of the user's audio blobs (Storage is not
  //    cascade-deleted). Failures are logged but do not block deletion.
  try {
    const files = await listAllFiles(supabase, AUDIO_BUCKET, user.id);
    for (let i = 0; i < files.length; i += 100) {
      const chunk = files.slice(i, i + 100);
      const { error: rmErr } = await supabase.storage
        .from(AUDIO_BUCKET)
        .remove(chunk);
      if (rmErr) console.error("storage remove failed:", rmErr.message);
    }
  } catch (e) {
    console.error(
      "storage cleanup error:",
      e instanceof Error ? e.message : String(e),
    );
  }

  // 2. Delete the auth user; app tables cascade from auth.users(id).
  const { error: delErr } = await supabase.auth.admin.deleteUser(user.id);
  if (delErr) {
    console.error("deleteUser failed:", delErr.message);
    return jsonResponse({ error: "Failed to delete account" }, 500);
  }

  return jsonResponse({ ok: true }, 200);
});
