-- ===========================================================================
-- SafeCheck-In — Supabase schema  (Office of Information Management and
-- Analysis / OIMA · org code 0270 · California State Water Resources Control
-- Board). Run once: SQL Editor → New query → paste → Run.
-- ===========================================================================

-- --- Tables ----------------------------------------------------------------

-- The editable roster (add / edit / remove people in the app's Admin panel).
create table if not exists public.employees (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  unit        text,
  title       text,
  sort_order  int not null default 0,
  created_at  timestamptz not null default now()
);

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
  employee_id    text not null,          -- employees.id (kept as text)
  employee_name  text not null,          -- denormalized so history survives roster edits
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
alter publication supabase_realtime add table public.employees;
alter publication supabase_realtime add table public.responses;
alter publication supabase_realtime add table public.events;

-- --- Row Level Security -----------------------------------------------------
-- Only a signed-in user (i.e. someone who entered the office passcode) can
-- read or write. The public "anon" key alone cannot touch the data.
alter table public.employees enable row level security;
alter table public.events    enable row level security;
alter table public.responses enable row level security;

create policy "signed-in all employees" on public.employees
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "signed-in all events" on public.events
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "signed-in all responses" on public.responses
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- --- Seed the roster (OIMA employee master; vacant positions excluded) ------
insert into public.employees (name, unit, title, sort_order) values
  ('Greg Gearheart','Executive','CEA A, Director',0),
  ('Andrew Hamilton','Management','Environmental Program Manager I (Sup)',1),
  ('Kiranpreet (Kiran) Kaur','Data Integration and Analysis','Senior WRC Engineer (Sup.)',2),
  ('Allysen Calalang','Data Integration and Analysis','WRC Engineer',3),
  ('Julius Choi','Data Integration and Analysis','WRC Engineer',4),
  ('David Altare','Data Integration and Analysis','WRC Engineer',5),
  ('Swarnalakshmi (Swarna) Gopalarathnam','Data Integration and Analysis','Research Data Specialist III',6),
  ('Ranita Prasad','Quality Assurance','Senior Environmental Scientist (Spec)',7),
  ('Annarose Holder','Data and Equity','Sr. Environmental Scientist (Spec)',8),
  ('Marisa Van Dyke','Harmful Algal Bloom Program','Senior Environmental Scientist (Spec)',9),
  ('Carly Nilson','Harmful Algal Bloom Program','Senior Environmental Scientist (Spec)',10),
  ('Chad Fearing','Contracts/Budgets','Analyst II',11),
  ('Sarah Guest','Contracts/Budgets','Analyst II',12),
  ('Tessa Fojut','QA/Data Management','Senior Environmental Scientist (Sup)',13),
  ('Jennifer Salisbury','QA/Data Management','Environmental Scientist',14),
  ('Toni Marshall','QA/Data Management','Environmental Scientist',15),
  ('James “Tony” Gill','QA/Data Management','Environmental Scientist',16),
  ('Keenan Smith','QA/Data Management','Environmental Scientist',17),
  ('Candice Heinz','QA/Data Management','Environmental Scientist',18),
  ('Alyssa Crabbe','QA/Data Management','Scientific Aid',19),
  ('Kimberly Pham','QA/Data Management','Environmental Scientist',20),
  ('Alexandria Dunn','SWAMP Unit','Senior Environmental Scientist (Sup)',21),
  ('Elena Suglia','SWAMP Unit','Environmental Scientist',22),
  ('Felisha Walls','SWAMP Unit','Environmental Scientist',23),
  ('Michelle Tang','SWAMP Unit','Research Data Specialist III',24),
  ('Lindsey Metz','SWAMP Unit','Environmental Scientist',25),
  ('Devan Burke','SWAMP Unit','Environmental Scientist',26),
  ('Laura Webber','Monitoring Council','Environmental Program Manager I (Spec)',27),
  ('Erickson Burres','Clean Water Team','Sr. Environmental Scientist (Spec)',28),
  ('Patricia Orosz','Administrative Support','Office Technician (T)',29);

-- --- Seed the first event so the board works immediately --------------------
insert into public.events (name, event_date, status)
values ('Gas leak at CalEPA HQ', '2026-07-14', 'active');
