-- Requested: finance@dimahmusic.com remains finance manager;
-- Mohamed EMP-0013 becomes an ordinary employee with Senior job level.
-- Run AFTER install_employee_job_levels.sql. Preserves Auth and all task/history rows.
begin;
do $repair$
declare
  v_tenant constant uuid := '550e8400-e29b-41d4-a716-446655440000';
  v_mahrous constant uuid := 'f89b220a-2672-4719-99be-fbe195bfed0a';
  v_finance public.users%rowtype;
  v_account public.users%rowtype;
  v_count integer;
begin
  lock table public.users in share row exclusive mode;
  select count(*) into v_count from public.users where tenant_id = v_tenant
    and lower(btrim(email)) = 'finance@dimahmusic.com';
  if v_count <> 1 then raise exception 'Expected one main finance account; inspect before repair'; end if;
  select * into v_finance from public.users where tenant_id = v_tenant
    and lower(btrim(email)) = 'finance@dimahmusic.com' for update;
  if v_finance.role <> 'finance_manager' or v_finance.is_active is not true
    or not exists (select 1 from public.employees where id = v_finance.employee_id
      and tenant_id = v_tenant and status = 'active') then
    raise exception 'Main finance must be active finance_manager linked to an active employee';
  end if;
  select count(*) into v_count from public.users where tenant_id = v_tenant
    and lower(btrim(email)) = 'mohamedmahrous@dimahmusic.com';
  if v_count <> 1 then raise exception 'Expected one Mahrous login account; inspect before repair'; end if;
  select * into v_account from public.users where tenant_id = v_tenant
    and lower(btrim(email)) = 'mohamedmahrous@dimahmusic.com' for update;
  if v_account.employee_id is distinct from v_mahrous or v_account.is_active is not true
    or v_account.role not in ('manager','direct_manager','employee')
    or not exists (select 1 from auth.users where id = v_account.id
      and lower(btrim(email)) = 'mohamedmahrous@dimahmusic.com')
    or v_finance.employee_id = v_mahrous then
    raise exception 'Mahrous account link or role changed; inspect before repair';
  end if;
  perform 1 from public.employees where id in (v_mahrous,v_finance.employee_id)
    and tenant_id = v_tenant for update;
  if not exists (select 1 from public.employees where id = v_mahrous
    and tenant_id = v_tenant and employee_number = 'EMP-0013' and status = 'active'
    and lower(btrim(email)) = 'mohamedmahrous@dimahmusic.com') then
    raise exception 'Correct Mahrous employee missing or inactive';
  end if;
  if exists (select 1 from public.employees where manager_id = v_mahrous and tenant_id = v_tenant)
    or exists (select 1 from public.departments where manager_id = v_mahrous and tenant_id = v_tenant) then
    raise exception 'Mahrous still manages employees or a department; review reporting lines first';
  end if;
  update public.users set role = 'employee' where id = v_account.id and tenant_id = v_tenant;
  update public.employees set job_level = 'senior', manager_id = v_finance.employee_id
    where id = v_mahrous and tenant_id = v_tenant;
end;
$repair$;
select u.email,u.role,e.employee_number,e.job_level,
  e.manager_id,m.employee_number as manager_number,m.full_name as reports_to
from public.users u join public.employees e on e.id = u.employee_id and e.tenant_id = u.tenant_id
left join public.employees m on m.id = e.manager_id and m.tenant_id = e.tenant_id
where u.tenant_id = '550e8400-e29b-41d4-a716-446655440000'::uuid
  and lower(btrim(u.email)) in ('finance@dimahmusic.com','mohamedmahrous@dimahmusic.com');
commit;
