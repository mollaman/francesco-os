-- Francesco OS - database (incolla tutto in Supabase > SQL Editor > Run)

create table if not exists public.daily_checkins (
  id            bigint generated always as identity primary key,
  user_id       uuid not null default auth.uid() references auth.users(id) on delete cascade,
  day           date not null,
  gym           boolean not null default false,
  tennis        boolean not null default false,
  stretching_min int not null default 0 check (stretching_min between 0 and 300),
  meditation_min int not null default 0 check (meditation_min between 0 and 300),
  spanish_min   int not null default 0 check (spanish_min between 0 and 600),
  english_pron  boolean not null default false,
  house_action  boolean not null default false,
  project_hours numeric(4,1) not null default 0 check (project_hours between 0 and 24),
  senior_contact boolean not null default false,
  priority_done boolean not null default false,
  impulsive     int not null default 0 check (impulsive between 0 and 20),
  pause_used    boolean not null default false,
  energy        int check (energy between 1 and 5),
  day_quality   int check (day_quality between 1 and 5),
  note          text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (user_id, day)
);

-- Sicurezza: ognuno vede e modifica SOLO le proprie righe
alter table public.daily_checkins enable row level security;

revoke all on public.daily_checkins from anon;
grant select, insert, update, delete on public.daily_checkins to authenticated;

drop policy if exists "own_select" on public.daily_checkins;
drop policy if exists "own_insert" on public.daily_checkins;
drop policy if exists "own_update" on public.daily_checkins;
drop policy if exists "own_delete" on public.daily_checkins;

create policy "own_select" on public.daily_checkins for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "own_insert" on public.daily_checkins for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "own_update" on public.daily_checkins for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "own_delete" on public.daily_checkins for delete to authenticated
  using ((select auth.uid()) = user_id);
