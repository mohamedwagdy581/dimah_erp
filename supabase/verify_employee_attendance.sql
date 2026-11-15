-- Optional SQL integration test after installation. All writes are rolled back.
-- Requires one active linked employee with an attendance record.
begin;
do $$
declare
  actor public.users%rowtype;
  rec public.attendance_records%rowtype;
  foreign_id uuid;
  result jsonb;
  first_id uuid;
  second_id uuid;
  ci timestamptz;
  co timestamptz;
begin
  perform set_config('request.jwt.claim.sub', '', true);
  begin
    perform public.employee_attendance_month(current_date);
    raise exception 'FAIL: unauthenticated request was allowed';
  exception when insufficient_privilege then null;
  end;
  select u.* into actor from public.users u where u.role = 'employee' and u.is_active is true
    and exists (select 1 from public.attendance_records r where r.employee_id = u.employee_id and r.tenant_id = u.tenant_id) limit 1;
  if not found then raise exception 'Create a test employee attendance record before running this test'; end if;
  select * into rec from public.attendance_records where employee_id = actor.employee_id and tenant_id = actor.tenant_id order by date desc limit 1;
  perform set_config('request.jwt.claim.sub', actor.id::text, true);
  result := public.employee_attendance_month(rec.date);
  if exists (select 1 from jsonb_array_elements(result -> 'records') r
    where r ->> 'employee_id' <> actor.employee_id::text or r ->> 'tenant_id' <> actor.tenant_id::text) then
    raise exception 'FAIL: foreign attendance was returned';
  end if;
  ci := coalesce(rec.check_in, rec.date::timestamptz + interval '8 hours') + interval '1 minute';
  co := ci + interval '8 hours';
  begin
    perform public.employee_request_attendance_correction(rec.id, co, ci, 'test invalid order');
    raise exception 'FAIL: invalid time order was accepted';
  exception when invalid_parameter_value then null;
  end;
  select id into foreign_id from public.attendance_records where employee_id <> actor.employee_id limit 1;
  if foreign_id is not null then
    begin
      perform public.employee_request_attendance_correction(foreign_id, ci, co, 'test ownership');
      raise exception 'FAIL: foreign record correction was accepted';
    exception when insufficient_privilege then null;
    end;
  end if;
  first_id := public.employee_request_attendance_correction(rec.id, ci, co, 'test retry');
  second_id := public.employee_request_attendance_correction(rec.id, ci, co, 'test retry');
  if first_id <> second_id then raise exception 'FAIL: retry created another pending request'; end if;
  if (select check_in from public.attendance_records where id = rec.id) is distinct from rec.check_in
     or (select check_out from public.attendance_records where id = rec.id) is distinct from rec.check_out then
    raise exception 'FAIL: requesting a correction modified attendance directly';
  end if;
  if has_function_privilege('anon', 'public.employee_attendance_month(date)', 'EXECUTE') then
    raise exception 'FAIL: anonymous role can execute employee RPC';
  end if;
  raise notice 'PASS: ownership, read scope, time validation, retry idempotency and unchanged attendance';
end;
$$;
rollback;
