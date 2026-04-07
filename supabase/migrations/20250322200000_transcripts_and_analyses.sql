-- Extend audio_notes with granular processing statuses.
-- Add tables for transcription results and AI startup analyses.

-- 1. Replace status constraint with granular processing stages
alter table public.audio_notes
  drop constraint audio_notes_status_check,
  add constraint audio_notes_status_check
    check (status in (
      'draft',
      'uploaded',
      'processing_transcription',
      'processing_analysis',
      'completed',
      'failed'
    ));

-- Migrate any legacy 'processing' rows (shouldn't exist yet, safety net)
update public.audio_notes
  set status = 'uploaded'
  where status = 'processing';

-- 2. audio_note_transcripts — one transcript per note (MVP)
create table if not exists public.audio_note_transcripts (
  id uuid primary key default gen_random_uuid(),
  audio_note_id uuid not null references public.audio_notes (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  transcript_text text not null,
  language text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint audio_note_transcripts_note_unique unique (audio_note_id)
);

create index if not exists audio_note_transcripts_note_idx
  on public.audio_note_transcripts (audio_note_id);

create or replace function public.set_transcripts_updated_at()
returns trigger language plpgsql security invoker set search_path = public as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists transcripts_set_updated_at on public.audio_note_transcripts;
create trigger transcripts_set_updated_at
  before update on public.audio_note_transcripts
  for each row execute function public.set_transcripts_updated_at();

alter table public.audio_note_transcripts enable row level security;

create policy "transcripts_select_own" on public.audio_note_transcripts
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "transcripts_insert_own" on public.audio_note_transcripts
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "transcripts_update_own" on public.audio_note_transcripts
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "transcripts_delete_own" on public.audio_note_transcripts
  for delete to authenticated using ((select auth.uid()) = user_id);

-- 3. startup_analyses — structured AI output per note (MVP: one per note)
create table if not exists public.startup_analyses (
  id uuid primary key default gen_random_uuid(),
  audio_note_id uuid not null references public.audio_notes (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  short_summary text,
  startup_title text,
  problem text,
  solution text,
  target_audience text,
  business_model text,
  key_metrics text,
  advantages text,
  risks_gaps text,
  follow_up_questions jsonb,
  raw_ai_response jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint startup_analyses_note_unique unique (audio_note_id)
);

create index if not exists startup_analyses_note_idx
  on public.startup_analyses (audio_note_id);

create or replace function public.set_analyses_updated_at()
returns trigger language plpgsql security invoker set search_path = public as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists analyses_set_updated_at on public.startup_analyses;
create trigger analyses_set_updated_at
  before update on public.startup_analyses
  for each row execute function public.set_analyses_updated_at();

alter table public.startup_analyses enable row level security;

create policy "analyses_select_own" on public.startup_analyses
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "analyses_insert_own" on public.startup_analyses
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "analyses_update_own" on public.startup_analyses
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "analyses_delete_own" on public.startup_analyses
  for delete to authenticated using ((select auth.uid()) = user_id);

-- 4. Enable realtime for audio_notes so the client can subscribe to status changes
alter publication supabase_realtime add table public.audio_notes;
