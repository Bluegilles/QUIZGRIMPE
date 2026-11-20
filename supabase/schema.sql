-- Le Quiz de la Grimpe : table des scores et classement.
-- À coller une fois dans Supabase : SQL Editor → New query → Run.

create table if not exists public.scores (
  id         bigint generated always as identity primary key,
  device     uuid not null,                       -- identifiant anonyme du navigateur du joueur
  pseudo     text not null check (char_length(pseudo) between 1 and 30),
  quiz       date not null,                       -- jour du quiz joué
  jour       date not null default current_date,  -- jour où il a été joué
  score      int  not null check (score between 0 and 500),
  created_at timestamptz not null default now(),
  unique (device, quiz)                           -- un seul score par joueur et par quiz
);

alter table public.scores enable row level security;

-- Les joueurs peuvent seulement ajouter leur score (pas lire la table, ni modifier, ni supprimer).
drop policy if exists "ajout" on public.scores;
create policy "ajout" on public.scores for insert to anon
  with check (quiz between current_date - 90 and current_date + 1);
revoke all on public.scores from anon, authenticated;
grant insert on public.scores to anon;

-- Classement d'une période : rang, pseudo, points, nombre de quiz, et « moi » pour repérer le joueur.
create or replace function public.classement(debut date, fin date, moi uuid default null)
returns table (rang bigint, pseudo text, points bigint, parties bigint, est_moi boolean)
language sql stable security definer set search_path = public as $$
  select rank() over (order by sum(s.score) desc)          as rang,
         (array_agg(s.pseudo order by s.created_at desc))[1] as pseudo,
         sum(s.score)::bigint                                as points,
         count(*)                                            as parties,
         coalesce(s.device = moi, false)                     as est_moi
  from public.scores s
  where s.quiz between debut and fin
  group by s.device
  order by points desc, min(s.created_at);
$$;
revoke all on function public.classement(date, date, uuid) from public;
grant execute on function public.classement(date, date, uuid) to anon;
