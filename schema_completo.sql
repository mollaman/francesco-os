-- Francesco OS - DATABASE COMPLETO (v1 - v5)
-- Supabase > SQL Editor > New query > incolla TUTTO > Run
-- Sicuro da rilanciare: non cancella dati esistenti.

create table if not exists public.daily_checkins (
  id            bigint generated always as identity primary key,
  user_id       uuid not null default auth.uid() references auth.users(id) on delete cascade,
  day           date not null,
  gym           boolean not null default false,
  tennis        boolean not null default false,
  stretching_min int not null default 0,
  meditation_min int not null default 0,
  spanish_min   int not null default 0,
  english_pron  boolean not null default false,
  house_action  boolean not null default false,
  project_hours numeric(4,1) not null default 0,
  senior_contact boolean not null default false,
  priority_done boolean not null default false,
  impulsive     int not null default 0,
  pause_used    boolean not null default false,
  energy        int check (energy between 1 and 5),
  day_quality   int check (day_quality between 1 and 5),
  note          text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (user_id, day)
);

alter table public.daily_checkins
  add column if not exists wake_730          boolean not null default false,
  add column if not exists other_sport       boolean not null default false,
  add column if not exists healthy_food      boolean not null default false,
  add column if not exists alcohol_drinks    int     not null default 0,
  add column if not exists reading_min       int     not null default 0,
  add column if not exists journaling        boolean not null default false,
  add column if not exists self_insult       boolean not null default false,
  add column if not exists irony_defense     int     not null default 0,
  add column if not exists presence          int check (presence between 1 and 5),
  add column if not exists french_min        int     not null default 0,
  add column if not exists focus_90          boolean not null default false,
  add column if not exists new_conversations int     not null default 0,
  add column if not exists chased            boolean not null default false,
  add column if not exists dressed_well      boolean not null default false,
  add column if not exists creative_hobby    boolean not null default false;

create table if not exists public.goals (
  id          bigint generated always as identity primary key,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  area        text not null,
  kind        text not null default 'risultato',
  title       text not null,
  metric      text,
  target      text,
  status      text not null default 'attivo',
  progress    int  not null default 0 check (progress between 0 and 100),
  next_action text,
  deadline    date,
  steps       jsonb default '[]'::jsonb,
  link        text,
  notes       text,
  sort        int not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.goals add column if not exists link text;
alter table public.goals alter column steps drop not null;

create table if not exists public.weekly_reviews (
  id             bigint generated always as identity primary key,
  user_id        uuid not null default auth.uid() references auth.users(id) on delete cascade,
  week_start     date not null,
  best text, weak text, stalled text, evidence text, obstacle text,
  p1 text, p2 text, p3 text,
  spese_ok   boolean not null default false,
  invest_ok  boolean not null default false,
  sunday_ok  boolean not null default false,
  nophone_ok boolean not null default false,
  books_finished int not null default 0,
  rating int check (rating between 1 and 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, week_start)
);

create table if not exists public.routine_items (
  id        bigint generated always as identity primary key,
  user_id   uuid not null default auth.uid() references auth.users(id) on delete cascade,
  routine   text not null default 'mattina',      -- mattina | sera | principi
  sort      int  not null default 0,
  emoji     text,
  title     text not null,
  minutes   int  not null default 1,
  context   text,
  link      text,                                  -- collega al check-in, es. 'meditation_min:10'
  active    boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.routine_done (
  user_id  uuid not null default auth.uid() references auth.users(id) on delete cascade,
  day      date not null,
  item_id  bigint not null references public.routine_items(id) on delete cascade,
  done_at  timestamptz not null default now(),
  primary key (user_id, day, item_id)
);

create table if not exists public.body_measurements (
  id        bigint generated always as identity primary key,
  user_id   uuid not null default auth.uid() references auth.users(id) on delete cascade,
  day       date not null,
  weight    numeric(5,1),
  waist     numeric(5,1),
  chest     numeric(5,1),
  arm       numeric(5,1),
  shoulders numeric(5,1),
  thigh     numeric(5,1),
  body_fat  numeric(4,1),
  note      text,
  created_at timestamptz not null default now(),
  unique (user_id, day)
);

create table if not exists public.user_settings (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  data    jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

do $$
declare t text;
begin
  foreach t in array array['daily_checkins','goals','weekly_reviews','routine_items','routine_done','body_measurements','user_settings'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
    execute format('drop policy if exists own_all on public.%I', t);
    execute format('create policy own_all on public.%I for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id)', t);
  end loop;
end $$;

create or replace function public.ping()
returns timestamptz
language sql
security definer
set search_path = ''
as $$ select now() $$;

revoke all on function public.ping() from public;
grant execute on function public.ping() to anon, authenticated;


-- Check finale: 7 righe, tutte con rls = true
select relname as tabella, relrowsecurity as rls from pg_class
where relname in ('daily_checkins','goals','weekly_reviews','routine_items','routine_done','body_measurements','user_settings')
order by 1;
