-- Run in Supabase SQL Editor (same project as your other apps).
-- Studium cloud sync: one JSON blob per user (auth) or one shared row (gate mode, id = default).

create table if not exists public.studium_sync (
  id text primary key,
  progress jsonb not null default '{}'::jsonb,
  deleted_progress jsonb not null default '{}'::jsonb,
  saved_quizzes jsonb not null default '[]'::jsonb,
  deleted_quizzes jsonb not null default '{}'::jsonb,
  vocab_buckets jsonb,
  updated_at timestamptz not null default now()
);

alter table public.studium_sync enable row level security;

drop policy if exists "studium_select" on public.studium_sync;
drop policy if exists "studium_insert" on public.studium_sync;
drop policy if exists "studium_update" on public.studium_sync;

-- Signed-in user: own row (id = auth user uuid).
-- Gate mode (no auth): anon may read/write row id = 'default' only.
create policy "studium_select" on public.studium_sync
  for select using (
    id = auth.uid()::text
    or (id = 'default' and auth.role() in ('anon', 'authenticated'))
  );

create policy "studium_insert" on public.studium_sync
  for insert with check (
    id = auth.uid()::text
    or (id = 'default' and auth.role() in ('anon', 'authenticated'))
  );

create policy "studium_update" on public.studium_sync
  for update using (
    id = auth.uid()::text
    or (id = 'default' and auth.role() in ('anon', 'authenticated'))
  );
