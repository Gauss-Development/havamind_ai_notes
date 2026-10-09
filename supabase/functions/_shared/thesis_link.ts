/**
 * Attach a processed audio note to the account's single concept.
 * process-audio-note links the note and does not rewrite the concept.
 * apply-debrief-to-thesis links, then rewrites only after a confirmed hearer
 * or an explicit unheard rewrite.
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
