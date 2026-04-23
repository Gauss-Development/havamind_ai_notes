-- Tags and note-tag associations (GAU-53).
-- RLS: users can only access their own tags and note_tags.
-- No direct client writes to note_tags — managed via TagsRemoteDataSource.

-- 1. tags — user-owned tag definitions
create table if not exists public.tags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  constraint tags_user_name_unique unique (user_id, name)
);

create index if not exists tags_user_idx on public.tags (user_id);

alter table public.tags enable row level security;

create policy "tags_all_own" on public.tags
  for all to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- 2. note_tags — junction table linking audio_notes to tags
create table if not exists public.note_tags (
  audio_note_id uuid not null references public.audio_notes (id) on delete cascade,
  tag_id uuid not null references public.tags (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (audio_note_id, tag_id)
);

create index if not exists note_tags_tag_idx on public.note_tags (tag_id);

alter table public.note_tags enable row level security;

create policy "note_tags_all_own" on public.note_tags
  for all to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
