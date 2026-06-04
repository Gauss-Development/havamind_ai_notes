-- Full-text search over note titles and transcript bodies (RLS-safe RPC).

alter table public.audio_note_transcripts
  add column if not exists transcript_tsv tsvector
  generated always as (to_tsvector('simple', coalesce(transcript_text, ''))) stored;

create index if not exists audio_note_transcripts_tsv_idx
  on public.audio_note_transcripts using gin (transcript_tsv);

create or replace function public.search_audio_notes(
  p_query text,
  p_limit int default 20
)
returns table (
  id uuid,
  user_id uuid,
  title text,
  audio_path text,
  duration_seconds int,
  status text,
  created_at timestamptz,
  updated_at timestamptz,
  last_processing_error text,
  match_type text,
  match_excerpt text
)
language plpgsql
stable
security invoker
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_query text := trim(p_query);
  v_pattern text;
  v_tsquery tsquery;
begin
  if v_user_id is null then
    raise exception 'Not signed in';
  end if;

  if v_query = '' then
    return;
  end if;

  v_pattern := '%' || replace(replace(replace(v_query, '\', '\\'), '%', '\%'), '_', '\_') || '%';
  v_tsquery := plainto_tsquery('simple', v_query);

  return query
  with scored as (
    select
      n.id,
      n.user_id,
      n.title,
      n.audio_path,
      n.duration_seconds,
      n.status,
      n.created_at,
      n.updated_at,
      n.last_processing_error,
      case
        when n.title ilike v_pattern escape '\' then 'title'
        else 'transcript'
      end as match_type,
      case
        when n.title ilike v_pattern escape '\' then null::text
        when t.transcript_text is not null
             and v_tsquery <> ''::tsquery
             and t.transcript_tsv @@ v_tsquery then
          ts_headline(
            'simple',
            t.transcript_text,
            v_tsquery,
            'MaxFragments=1, MaxWords=15, MinWords=4, ShortWord=0'
          )
        when t.transcript_text is not null
             and position(lower(v_query) in lower(t.transcript_text)) > 0 then
          '…' || substr(
            t.transcript_text,
            greatest(1, position(lower(v_query) in lower(t.transcript_text)) - 25),
            least(length(t.transcript_text), length(v_query) + 50)
          ) || '…'
        else null::text
      end as match_excerpt,
      case
        when n.title ilike v_pattern escape '\' then 0
        else 1
      end as title_priority,
      coalesce(ts_rank(t.transcript_tsv, v_tsquery), 0)::real as transcript_rank
    from public.audio_notes n
    left join public.audio_note_transcripts t
      on t.audio_note_id = n.id and t.user_id = n.user_id
    where n.user_id = v_user_id
      and (
        n.title ilike v_pattern escape '\'
        or (t.transcript_text is not null and t.transcript_text ilike v_pattern escape '\')
        or (t.transcript_tsv is not null and t.transcript_tsv @@ v_tsquery)
      )
  )
  select
    s.id,
    s.user_id,
    s.title,
    s.audio_path,
    s.duration_seconds,
    s.status,
    s.created_at,
    s.updated_at,
    s.last_processing_error,
    s.match_type,
    s.match_excerpt
  from scored s
  order by s.title_priority, s.transcript_rank desc, s.created_at desc
  limit greatest(1, least(coalesce(nullif(p_limit, 0), 20), 50));
end;
$$;

grant execute on function public.search_audio_notes(text, int) to authenticated;
