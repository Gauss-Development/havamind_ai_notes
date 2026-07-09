-- Ephemeral audio storage.
--
-- The `audio-notes` bucket is a staging area for the processing pipeline, not
-- a long-term media library. Once a note reaches `completed`, the edge
-- function `process-audio-note` removes the raw blob and nulls `audio_path`;
-- the transcript and analysis are the durable artifacts. This migration lets
-- `audio_path` be null and backfills already-completed notes.
alter table public.audio_notes
  alter column audio_path drop not null;

-- Backfill: completed notes no longer need a storage key. (Their blobs are
-- cleaned up separately via the one-time Storage audit.)
update public.audio_notes
  set audio_path = null
  where status = 'completed' and audio_path is not null;
