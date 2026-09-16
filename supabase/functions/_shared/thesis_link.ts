/**
 * Attach a processed audio note to the account's single living thesis.
 * Used by process-audio-note (after completion) and apply-debrief-to-thesis.
 */

// deno-lint-ignore no-explicit-any
export type ThesisLinkClient = any;

export async function getOrCreateUserThesisId(
  supabase: ThesisLinkClient,
  userId: string,
): Promise<string> {
  const { data: existing, error: readErr } = await supabase
    .from("theses")
    .select("id")
    .eq("user_id", userId)
    .maybeSingle();

  if (readErr) {
    throw new Error(readErr.message);
  }
  if (existing?.id) {
    return existing.id as string;
  }

  const { data: created, error: insertErr } = await supabase
    .from("theses")
    .insert({ user_id: userId, field_evidence: {} })
    .select("id")
    .single();

  if (!insertErr && created?.id) {
    return created.id as string;
  }

  // Concurrent first note: unique(user_id) lost the race.
  if (insertErr?.code === "23505") {
    const { data: again, error: retryErr } = await supabase
      .from("theses")
      .select("id")
      .eq("user_id", userId)
      .maybeSingle();
    if (retryErr) throw new Error(retryErr.message);
    if (again?.id) return again.id as string;
  }

  throw new Error(insertErr?.message ?? "Failed to create thesis");
}

export async function linkNoteToUserThesis(
  supabase: ThesisLinkClient,
  userId: string,
  noteId: string,
): Promise<string> {
  const thesisId = await getOrCreateUserThesisId(supabase, userId);
  const { error } = await supabase
    .from("audio_notes")
    .update({ thesis_id: thesisId })
    .eq("id", noteId)
    .eq("user_id", userId);
  if (error) {
    throw new Error(error.message);
  }
  return thesisId;
}

export function applyDebriefFunctionUrl(supabaseUrl: string): string {
  return `${supabaseUrl.replace(/\/$/, "")}/functions/v1/apply-debrief-to-thesis`;
}

export async function invokeApplyDebriefToThesis(opts: {
  supabaseUrl: string;
  authorization: string;
  apikey: string;
  noteId: string;
}): Promise<{ ok: boolean; status: number }> {
  const res = await fetch(applyDebriefFunctionUrl(opts.supabaseUrl), {
    method: "POST",
    headers: {
      Authorization: opts.authorization,
      apikey: opts.apikey,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ note_id: opts.noteId }),
  });
  if (!res.ok) {
    const text = await res.text();
    console.error(
      `[process-audio-note] apply-debrief-to-thesis failed (${res.status}): ${text}`,
    );
  }
  return { ok: res.ok, status: res.status };
}
