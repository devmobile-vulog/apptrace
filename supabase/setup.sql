-- AppTrace — full Supabase setup
-- Paste this entire script into Supabase Dashboard → SQL Editor → Run.
--
-- What it creates:
--   • network_logs table + indexes
--   • RLS policies and grants for anon/authenticated inserts
--   • cleanup function that deletes logs older than 7 days
--   • weekly pg_cron job to run that cleanup automatically
--
-- Note: pg_cron must be enabled in Dashboard → Database → Extensions.
-- If cron scheduling fails, enable the "pg_cron" extension first, then
-- re-run only the "Cron job" section at the bottom.

-- ---------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------

create table if not exists public.network_logs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  app_id text,
  session_id text,
  method text not null,
  url text not null,
  status_code integer,
  request_headers jsonb not null default '{}'::jsonb,
  response_headers jsonb not null default '{}'::jsonb,
  request_body text,
  response_body text,
  duration_ms integer,
  error text,
  metadata jsonb not null default '{}'::jsonb
);

create index if not exists network_logs_created_at_idx
  on public.network_logs (created_at desc);

create index if not exists network_logs_app_id_idx
  on public.network_logs (app_id);

comment on table public.network_logs is
  'HTTP traffic logs captured by the AppTrace Flutter package.';

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------

alter table public.network_logs enable row level security;

grant usage on schema public to anon, authenticated;
grant insert on public.network_logs to anon, authenticated;
grant select on public.network_logs to authenticated;

drop policy if exists "Allow anon insert network logs" on public.network_logs;
create policy "Allow anon insert network logs"
  on public.network_logs
  for insert
  to anon
  with check (true);

drop policy if exists "Allow authenticated insert network logs"
  on public.network_logs;
create policy "Allow authenticated insert network logs"
  on public.network_logs
  for insert
  to authenticated
  with check (true);

-- Dashboard: authenticated users can read logs (sign in via Supabase Auth).
drop policy if exists "Allow authenticated read network logs" on public.network_logs;
create policy "Allow authenticated read network logs"
  on public.network_logs
  for select
  to authenticated
  using (true);

create or replace function public.apptrace_dashboard_setup_status()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  row_count bigint;
begin
  select count(*) into row_count from public.network_logs;
  return jsonb_build_object('table_row_count', row_count);
end;
$$;

revoke all on function public.apptrace_dashboard_setup_status() from public;
grant execute on function public.apptrace_dashboard_setup_status()
  to anon, authenticated;

-- Live updates in the dashboard (optional but recommended).
alter publication supabase_realtime add table public.network_logs;

-- ---------------------------------------------------------------------------
-- Retention cleanup (delete logs older than 7 days)
-- ---------------------------------------------------------------------------

create or replace function public.apptrace_cleanup_old_network_logs(
  retention_days integer default 7
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_count bigint;
begin
  if retention_days < 1 then
    raise exception 'retention_days must be at least 1';
  end if;

  delete from public.network_logs
  where created_at < now() - make_interval(days => retention_days);

  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$;

revoke all on function public.apptrace_cleanup_old_network_logs(integer)
  from public;
grant execute on function public.apptrace_cleanup_old_network_logs(integer)
  to postgres, service_role;

comment on function public.apptrace_cleanup_old_network_logs(integer) is
  'Deletes network_logs rows older than retention_days (default 7).';

-- Manual test:
-- select public.apptrace_cleanup_old_network_logs(7);

-- ---------------------------------------------------------------------------
-- Cron job (runs every Sunday at 03:00 UTC)
-- ---------------------------------------------------------------------------

create extension if not exists pg_cron with schema extensions;

do $$
declare
  existing_job_id bigint;
begin
  select jobid
  into existing_job_id
  from cron.job
  where jobname = 'apptrace-purge-network-logs-weekly';

  if existing_job_id is not null then
    perform cron.unschedule(existing_job_id);
  end if;
end $$;

select cron.schedule(
  'apptrace-purge-network-logs-weekly',
  '0 3 * * 0',
  $$select public.apptrace_cleanup_old_network_logs(7);$$
);

-- Verify scheduled jobs:
-- select * from cron.job where jobname = 'apptrace-purge-network-logs-weekly';
