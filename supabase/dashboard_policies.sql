-- AppTrace dashboard policies (run if you already executed setup.sql before)
-- Adds read access for authenticated users and realtime for live updates.

grant select on public.network_logs to authenticated;

drop policy if exists "Allow authenticated read network logs" on public.network_logs;
create policy "Allow authenticated read network logs"
  on public.network_logs
  for select
  to authenticated
  using (true);

-- Helps the dashboard detect "logs exist but read access is missing".
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

alter publication supabase_realtime add table public.network_logs;
