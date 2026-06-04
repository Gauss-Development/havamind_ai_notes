-- Recording template id persisted on each note (MVP: founder_pitch | customer_discovery | investor_update)
alter table public.audio_notes
  add column if not exists template_id text not null default 'founder_pitch';

update public.audio_notes
set template_id = 'founder_pitch'
where template_id is null or template_id = '';

alter table public.audio_notes
  add constraint audio_notes_template_id_check
  check (template_id in ('founder_pitch', 'customer_discovery', 'investor_update'));

comment on column public.audio_notes.template_id is
  'Recording/analysis template: founder_pitch (default), customer_discovery, investor_update';
