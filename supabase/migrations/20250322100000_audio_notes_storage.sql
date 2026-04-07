-- audio_notes: voice notes metadata. RLS: users only see own rows.
-- Storage bucket audio-notes: private; path layout user_id/note_id/filename

create table if not exists public.audio_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  audio_path text not null,
  duration_seconds int not null check (duration_seconds >= 0),
  status text not null check (status in ('draft', 'uploaded', 'processing', 'completed', 'failed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists audio_notes_user_id_created_at_idx
  on public.audio_notes (user_id, created_at desc);

create or replace function public.set_audio_notes_updated_at()
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

drop trigger if exists audio_notes_set_updated_at on public.audio_notes;
create trigger audio_notes_set_updated_at
before update on public.audio_notes
for each row
execute function public.set_audio_notes_updated_at();

alter table public.audio_notes enable row level security;

drop policy if exists "audio_notes_select_own" on public.audio_notes;
create policy "audio_notes_select_own"
on public.audio_notes
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "audio_notes_insert_own" on public.audio_notes;
create policy "audio_notes_insert_own"
on public.audio_notes
for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "audio_notes_update_own" on public.audio_notes;
create policy "audio_notes_update_own"
on public.audio_notes
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "audio_notes_delete_own" on public.audio_notes;
create policy "audio_notes_delete_own"
on public.audio_notes
for delete
to authenticated
using ((select auth.uid()) = user_id);

-- Private bucket for user audio (id must match bucket name used in client)
insert into storage.buckets (id, name, public)
values ('audio-notes', 'audio-notes', false)
on conflict (id) do update set public = excluded.public;

-- Storage policies: first path segment must equal auth.uid()
drop policy if exists "audio_notes_storage_select" on storage.objects;
create policy "audio_notes_storage_select"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'audio-notes'
  and split_part(name, '/', 1) = (select auth.uid())::text
);

drop policy if exists "audio_notes_storage_insert" on storage.objects;
create policy "audio_notes_storage_insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'audio-notes'
  and split_part(name, '/', 1) = (select auth.uid())::text
);

drop policy if exists "audio_notes_storage_update" on storage.objects;
create policy "audio_notes_storage_update"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'audio-notes'
  and split_part(name, '/', 1) = (select auth.uid())::text
)
with check (
  bucket_id = 'audio-notes'
  and split_part(name, '/', 1) = (select auth.uid())::text
);

drop policy if exists "audio_notes_storage_delete" on storage.objects;
create policy "audio_notes_storage_delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'audio-notes'
  and split_part(name, '/', 1) = (select auth.uid())::text
);
