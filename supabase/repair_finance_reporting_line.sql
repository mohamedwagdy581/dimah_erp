-- Follow-up to the observed result: Finance still reports to Mohamed Mahrous.
-- Clears only the retired EMP-0004 link, never an unknown/current manager.
-- Does not select a replacement manager, change roles, or modify tasks/payroll.
begin;
do $repair$
declare
  v_tenant constant uuid := '550e8400-e29b-41d4-a716-446655440000';
  v_old constant uuid := 'b2039a64-4b86-440b-87a6-2a776744aed4';
  v_mahrous constant uuid := 'f89b220a-2672-4719-99be-fbe195bfed0a';
  v_account public.users%rowtype;
  v_finance public.employees%rowtype;
  v_duplicate public.employees%rowtype;
  v_count integer;
begin
  select count(*) into v_count from public.users where tenant_id = v_tenant
    and lower(btrim(email)) = 'finance@dimahmusic.com';
  if v_count <> 1 then raise exception 'Expected one main finance account'; end if;
  select * into v_account from public.users where tenant_id = v_tenant
    and lower(btrim(email)) = 'finance@dimahmusic.com' for update;
  if v_account.role is distinct from 'finance_manager' or v_account.is_active is not true then
    raise exception 'Finance account role/status changed; nothing changed';
  end if;
  select * into v_finance from public.employees where id = v_account.employee_id
    and tenant_id = v_tenant for update;
  if not found then raise exception 'Finance employee link missing'; end if;
  if v_finance.employee_number is distinct from 'EMP-0009'
    or v_finance.status is distinct from 'active' then
    raise exception 'Finance employee identity/status changed; nothing changed';
  end if;
  perform 1 from public.employees where id = v_mahrous and tenant_id = v_tenant
    and employee_number = 'EMP-0013' and status = 'active'
    and manager_id = v_finance.id and job_level = 'senior' for share;
  if not found then raise exception 'Mahrous reporting line changed; nothing changed'; end if;
  if v_finance.manager_id is null then
    raise notice 'Finance already has no reporting manager; no changes needed';
    return;
  end if;
  if v_finance.manager_id is distinct from v_old then
    raise exception 'Finance reports to another employee; inspect manager_id before changing it';
  end if;
  select * into v_duplicate from public.employees where id = v_old and tenant_id = v_tenant for share;
  if not found then raise exception 'Retired duplicate is missing'; end if;
  if v_duplicate.employee_number is distinct from 'EMP-0004'
    or v_duplicate.status is distinct from 'inactive'
    or v_duplicate.email is distinct from 'archived.b2039a64-4b86-440b-87a6-2a776744aed4@employee.invalid' then
    raise exception 'Old duplicate is not retired as expected; nothing changed';
  end if;
  update public.employees set manager_id = null where id = v_finance.id and tenant_id = v_tenant;
end;
$repair$;

select u.email,u.role,e.employee_number,e.job_level,
  e.manager_id, m.employee_number as manager_number,m.full_name as reports_to
from public.users u join public.employees e on e.id = u.employee_id and e.tenant_id = u.tenant_id
left join public.employees m on m.id = e.manager_id and m.tenant_id = e.tenant_id
where u.tenant_id = '550e8400-e29b-41d4-a716-446655440000'::uuid
  and lower(btrim(u.email)) in ('finance@dimahmusic.com','mohamedmahrous@dimahmusic.com');
commit;
