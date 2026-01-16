create table if not exists debug_events (
  id bigint generated always as identity primary key,
  created_at timestamptz default now(),
  device_id text,
  stage text,
  payload jsonb
);

alter table debug_events enable row level security;

create policy "Enable insert for everyone" on debug_events for insert with check (true);
create policy "Enable select for everyone" on debug_events for select using (true);
