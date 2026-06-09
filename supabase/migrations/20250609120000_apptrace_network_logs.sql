-- AppTrace network logs table for Supabase (PostgreSQL).
-- For a one-shot setup including cron retention, use supabase/setup.sql instead.

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

alter table public.network_logs enable row level security;

grant usage on schema public to anon, authenticated;
grant insert on public.network_logs to anon, authenticated;

drop policy if exists "Allow anon insert network logs" on public.network_logs;
create policy "Allow anon insert network logs"
  on public.network_logs
  for insert
  to anon
  with check (true);

drop policy if exists "Allow authenticated insert network logs" on public.network_logs;
create policy "Allow authenticated insert network logs"
  on public.network_logs
  for insert
  to authenticated
  with check (true);

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
