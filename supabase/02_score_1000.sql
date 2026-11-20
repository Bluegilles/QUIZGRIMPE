-- Les quiz font 8 questions (800 points max) : on accepte les scores jusqu'à 1000.
alter table public.scores drop constraint if exists scores_score_check;
alter table public.scores add constraint scores_score_check check (score between 0 and 1000);
