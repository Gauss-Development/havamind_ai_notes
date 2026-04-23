-- Plan version history for iterative refinement (GAU-94, GAU-95).
-- Each refinement round creates a new row; restores also create a new row (never destroy history).
-- RLS: users SELECT own rows; writes come from Edge Functions via service role.

-- 1. Add subscription_tier to profiles so Edge Functions can check tier
alter table public.profiles
  add column if not exists subscription_tier text not null default 'free'
  constraint profiles_subscription_tier_check
    check (subscription_tier in ('free', 'basic', 'pro'));

-- 2. plan_versions — one row per refinement round
create table if not exists public.plan_versions (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.startup_analyses (id) on delete cascade,
  audio_note_id uuid not null references public.audio_notes (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  round_number int not null default 1,
  plan_snapshot jsonb not null,
  transcription text not null,
  follow_up_questions jsonb,
  diff_summary text,
  context_summary text,
  follow_up_question_id text,
  created_at timestamptz not null default now(),
  constraint plan_versions_round_unique unique (plan_id, round_number)
);

create index if not exists plan_versions_plan_idx
  on public.plan_versions (plan_id, round_number);

create index if not exists plan_versions_audio_note_idx
  on public.plan_versions (audio_note_id);

alter table public.plan_versions enable row level security;

-- Users can read their own versions; writes come from service role only
create policy "plan_versions_select_own" on public.plan_versions
  for select to authenticated using ((select auth.uid()) = user_id);

-- 3. plan_refinement_sessions — groups refinement rounds into sessions
create table if not exists public.plan_refinement_sessions (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.startup_analyses (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  finalized_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists plan_refinement_sessions_plan_idx
  on public.plan_refinement_sessions (plan_id);

alter table public.plan_refinement_sessions enable row level security;

-- Users can read their own sessions; writes from service role only
create policy "plan_refinement_sessions_select_own"
  on public.plan_refinement_sessions
  for select to authenticated using ((select auth.uid()) = user_id);
