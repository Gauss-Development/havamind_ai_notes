-- Living thesis: one row per user. Audio notes stay events and point at it
-- via nullable audio_notes.thesis_id so existing notes keep working.
--
-- RLS mirrors startup_analyses for `theses` (select/insert/update/delete own)
-- so the client can seed from a completed analysis. `thesis_versions` mirrors
-- plan_versions: users SELECT own rows; writes come from the service role
-- (apply-debrief Edge Function, later).

-- 1. theses — one living thesis per account
create table if not exists public.theses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text,
  short_summary text,
  problem text,
  solution text,
  target_audience text,
  business_model text,
  key_metrics text,
  advantages text,
  risks_gaps text,
  follow_up_questions jsonb,
  next_conversation_script text,
  field_evidence jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint theses_user_unique unique (user_id)
);

create or replace function public.set_theses_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists theses_set_updated_at on public.theses;
create trigger theses_set_updated_at
  before update on public.theses
  for each row
  execute function public.set_theses_updated_at();

alter table public.theses enable row level security;

drop policy if exists "theses_select_own" on public.theses;
create policy "theses_select_own"
  on public.theses
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "theses_insert_own" on public.theses;
create policy "theses_insert_own"
  on public.theses
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "theses_update_own" on public.theses;
create policy "theses_update_own"
  on public.theses
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "theses_delete_own" on public.theses;
create policy "theses_delete_own"
  on public.theses
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- 2. thesis_versions — same contract as plan_versions (snapshot + diff + round)
create table if not exists public.thesis_versions (
  id uuid primary key default gen_random_uuid(),
  thesis_id uuid not null references public.theses (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  round_number int not null default 1,
  thesis_snapshot jsonb not null,
  transcription text not null,
  diff_summary text,
  follow_up_questions jsonb,
  created_at timestamptz not null default now(),
  constraint thesis_versions_round_unique unique (thesis_id, round_number)
);

create index if not exists thesis_versions_thesis_idx
  on public.thesis_versions (thesis_id, round_number);

alter table public.thesis_versions enable row level security;

drop policy if exists "thesis_versions_select_own" on public.thesis_versions;
create policy "thesis_versions_select_own"
  on public.thesis_versions
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

-- 3. audio_notes.thesis_id — nullable so current notes and inserts stay valid
alter table public.audio_notes
  add column if not exists thesis_id uuid references public.theses (id) on delete set null;

create index if not exists audio_notes_thesis_id_idx
  on public.audio_notes (thesis_id);
