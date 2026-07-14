-- ===========================================================================
-- SafeCheck-In — Supabase schema
-- Run this once in your Supabase project: SQL Editor → New query → paste → Run.
-- ===========================================================================

-- --- Tables ----------------------------------------------------------------

-- One row per activation / drill (e.g. "Gas leak at CalEPA HQ").
create table if not exists public.events (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  event_date  date,
  status      text not null default 'active',   -- 'active' | 'archived'
  created_at  timestamptz not null default now()
);

-- One row per employee per event (only created when someone marks a status).
create table if not exists public.responses (
  id             uuid primary key default gen_random_uuid(),
  event_id       uuid not null references public.events(id) on delete cascade,
  employee_id    int  not null,          -- index into the app's fixed roster
  employee_name  text not null,
  unit           text,
  title          text,
  status         text not null default 'pending',  -- 'pending' | 'safe' | 'help'
  note           text default '',
  updated_at     timestamptz not null default now(),
  updated_by     text default '',
  unique (event_id, employee_id)
);

-- --- Summary view (counts per event, used by the "Saved versions" list) -----
-- security_invoker = the view honors the caller's row-level security, so it
-- returns nothing to someone who hasn't signed in with the passcode.
create or replace view public.event_summary
  with (security_invoker = on) as
select
  e.id,
  e.name,
  e.event_date,
  e.status,
  e.created_at,
  count(r.*) filter (where r.status = 'safe') as safe,
  count(r.*) filter (where r.status = 'help') as help
from public.events e
left join public.responses r on r.event_id = e.id
group by e.id;

-- --- Realtime (so every device sees updates live) --------------------------
alter publication supabase_realtime add table public.responses;
alter publication supabase_realtime add table public.events;

-- --- Row Level Security -----------------------------------------------------
-- Only a signed-in user (i.e. someone who entered the office passcode) can
-- read or write. The public "anon" key alone cannot touch the data.
alter table public.events    enable row level security;
alter table public.responses enable row level security;

create policy "signed-in read events"  on public.events
  for select using (auth.role() = 'authenticated');
create policy "signed-in write events" on public.events
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "signed-in read responses"  on public.responses
  for select using (auth.role() = 'authenticated');
create policy "signed-in write responses" on public.responses
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- --- Seed the first event so the board works immediately --------------------
insert into public.events (name, event_date, status)
values ('Gas leak at CalEPA HQ', '2026-07-14', 'active');
