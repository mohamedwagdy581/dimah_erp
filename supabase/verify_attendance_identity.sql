-- Optional checks after install_attendance_identity.sql. All mapping changes roll back.
-- Run in SQL Editor as postgres. Needs an active HR/admin and employee in its company.
begin;
do $$
declare
  actor public.users%rowtype;
  employee_id uuid;
  second_employee_id uuid;
  other_company_employee_id uuid;
  test_number text := 'test_' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 20);
begin
  if has_function_privilege('anon', 'public.set_employee_attendance_identity(uuid,text)', 'EXECUTE')
     or has_function_privilege('authenticated', 'public.attendance_identity_actor()', 'EXECUTE') then
    raise exception 'Unexpected public/internal function permissions';
  end if;
  select * into actor from public.users where role in ('hr', 'admin') and is_active is true
    and exists (select 1 from public.employees where tenant_id = users.tenant_id) limit 1;
  if not found then raise exception 'Active HR/admin with a company employee needed'; end if;
  perform set_config('request.jwt.claim.sub', actor.id::text, true);
  select id into employee_id from public.employees where tenant_id = actor.tenant_id limit 1;
  perform public.set_employee_attendance_identity(employee_id, test_number);
  if public.get_employee_attendance_identity(employee_id) is distinct from test_number then
    raise exception 'Save/read identity mismatch';
  end if;
  perform public.set_employee_attendance_identity(employee_id, test_number);
  perform public.check_employee_attendance_identity(test_number, employee_id);

  select id into second_employee_id from public.employees
    where tenant_id = actor.tenant_id and id <> employee_id limit 1;
  if second_employee_id is not null then
    begin
      perform public.set_employee_attendance_identity(second_employee_id, test_number);
      raise exception 'Duplicate identity accepted';
    exception when unique_violation then null; end;
  else raise notice 'Duplicate employee check skipped: second employee needed'; end if;

  select id into other_company_employee_id from public.employees
    where tenant_id <> actor.tenant_id limit 1;
  if other_company_employee_id is not null then
    begin
      perform public.set_employee_attendance_identity(other_company_employee_id, test_number);
      raise exception 'Cross-company employee accepted';
    exception when insufficient_privilege then null; end;
  else raise notice 'Cross-company check skipped: another company employee needed'; end if;

  begin
    perform public.set_employee_attendance_identity(employee_id, 'invalid number');
    raise exception 'Invalid number accepted';
  exception when invalid_parameter_value then null; end;
  perform public.set_employee_attendance_identity(employee_id, '');
  if public.get_employee_attendance_identity(employee_id) is not null then
    raise exception 'Identity unlink failed';
  end if;
  perform set_config('request.jwt.claim.sub', '', true);
  begin
    perform public.get_employee_attendance_identity(employee_id);
    raise exception 'Unauthenticated identity read accepted';
  exception when insufficient_privilege then null; end;
  raise notice 'PASS: identity save/read/retry/unlink, validation and permissions. All changes roll back.';
end;
$$;
rollback;
