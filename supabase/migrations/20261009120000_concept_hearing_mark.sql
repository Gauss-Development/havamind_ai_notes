-- theses is the current pitch concept: the speech the founder will say next.
-- One row per user (theses.user_id stays UNIQUE). Replace its fields in full;
-- do not append paragraphs into the live speech.
--
-- thesis_versions are past speeches of that concept. After hearing_status
-- becomes 'heard', thesis_snapshot is immutable: the words already reached
-- someone's ears and must not be edited in place. Existing rows are append
-- rounds from the previous slice. They stay 'unheard' with no invented names.
-- Snapshots already stored are not rewritten.
--
-- RLS is unchanged: authenticated clients SELECT their own versions only.
-- Inserts and updates stay on the service role inside the Edge Function.
-- There is no listeners table and no foreign key from the label to auth.users.

comment on table public.theses is
  'Current pitch concept (one speech per account). Fields are replaced in full on rewrite; they are not an accumulating canvas.';

comment on column public.thesis_versions.thesis_snapshot is
  'Frozen speech. Immutable once hearing_status is heard; do not update this jsonb on a heard row.';

alter table public.thesis_versions
  add column if not exists hearing_status text not null default 'unheard',
  add column if not exists heard_by_label text,
  add column if not exists heard_at timestamptz;

alter table public.thesis_versions
  drop constraint if exists thesis_versions_hearing_check;

alter table public.thesis_versions
  add constraint thesis_versions_hearing_check
  check (
    hearing_status in ('unheard', 'heard')
    and (
      (
        hearing_status = 'heard'
        and heard_by_label is not null
        and char_length(btrim(heard_by_label)) between 1 and 120
      )
      or (
        hearing_status = 'unheard'
        and heard_by_label is null
        and heard_at is null
      )
    )
  );

comment on column public.thesis_versions.hearing_status is
  'unheard or heard. Migration default for existing snapshots is unheard.';

comment on column public.thesis_versions.heard_by_label is
  'Founder-confirmed label of who already heard this speech (1–120 chars after trim). Not a user id, not an email account.';

comment on column public.thesis_versions.heard_at is
  'When this version was marked heard. Null while unheard.';
