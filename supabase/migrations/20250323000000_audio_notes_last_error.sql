-- Optional server-side error text when processing fails (shown in UI).
alter table public.audio_notes
  add column if not exists last_processing_error text;
