-- Slice instrumentation for the 10-founder return test.
-- No analytics platform: debrief returns live on thesis_versions
-- (customer_discovery rows) plus denormalized counters on theses.
-- week_artifact_share_count increments only when the founder opens
-- the system share sheet — generating or copying the letter does not.

alter table public.theses
  add column if not exists debrief_count integer not null default 0,
  add column if not exists week_artifact_share_count integer not null default 0,
  add column if not exists week_artifact_shared_at timestamptz;

alter table public.theses
  drop constraint if exists theses_debrief_count_nonneg;
alter table public.theses
  add constraint theses_debrief_count_nonneg check (debrief_count >= 0);

alter table public.theses
  drop constraint if exists theses_week_share_count_nonneg;
alter table public.theses
  add constraint theses_week_share_count_nonneg
  check (week_artifact_share_count >= 0);

comment on column public.theses.debrief_count is
  'customer_discovery applies on this thesis. Second return = 2, third = 3. Cold pitch / seed do not increment.';
comment on column public.theses.week_artifact_share_count is
  'Times the weekly letter was handed to the OS share sheet. Copy and generate do not count.';
comment on column public.theses.week_artifact_shared_at is
  'Last successful weekly-artifact share.';

alter table public.thesis_versions
  add column if not exists source_note_id uuid
    references public.audio_notes (id) on delete set null,
  add column if not exists source_template_id text;

comment on column public.thesis_versions.source_template_id is
  'Recording template of the note that produced this version. Filter customer_discovery for debrief returns.';
comment on column public.thesis_versions.source_note_id is
  'Audio note that produced this version.';

-- Atomic increment so a double-tap cannot drop a share. RLS still applies
-- (security invoker): only the signed-in user's thesis row is updated.
create or replace function public.record_week_artifact_share()
returns setof public.theses
language sql
security invoker
set search_path = public
as $$
  update public.theses
  set
    week_artifact_share_count = week_artifact_share_count + 1,
    week_artifact_shared_at = now()
  where user_id = (select auth.uid())
  returning *;
$$;

revoke all on function public.record_week_artifact_share() from public;
grant execute on function public.record_week_artifact_share() to authenticated;
