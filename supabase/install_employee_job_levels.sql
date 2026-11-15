-- Job level is descriptive metadata, independent of the login role.
begin;
alter table public.employees add column if not exists job_level text;
do $$ begin
  if not exists (select 1 from pg_constraint where conrelid = 'public.employees'::regclass
    and conname = 'employees_job_level_check') then
    alter table public.employees add constraint employees_job_level_check
      check (job_level is null or job_level in ('junior','mid','senior'));
  end if;
end $$;

create or replace function public.employee_job_level(p_employee_id uuid)
returns text language plpgsql stable security definer set search_path = public, pg_temp as $$
declare v_tenant uuid; v_role text; v_employee uuid; v_level text;
begin
  select tenant_id,role,employee_id into v_tenant,v_role,v_employee from public.users
    where id = auth.uid() and is_active is true;
  if v_tenant is null then raise exception 'Forbidden' using errcode = '42501'; end if;
  select e.job_level into v_level from public.employees e where e.id = p_employee_id
    and e.tenant_id = v_tenant and (e.id = v_employee or v_role in ('hr','admin')
      or (v_role in ('finance_manager','manager','direct_manager') and
        (e.manager_id = v_employee or exists (select 1 from public.departments d
          where d.id = e.department_id and d.tenant_id = v_tenant and d.manager_id = v_employee))));
  if not found then raise exception 'Forbidden' using errcode = '42501'; end if;
  return v_level;
end $$;

create or replace function public.set_employee_job_level(p_employee_id uuid,p_level text)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_tenant uuid;
begin
  select tenant_id into v_tenant from public.users
    where id = auth.uid() and is_active is true and role in ('hr','admin');
  if v_tenant is null then raise exception 'Active HR/admin required' using errcode = '42501'; end if;
  if p_level is not null and p_level not in ('junior','mid','senior') then raise exception 'Invalid job level'; end if;
  update public.employees set job_level = p_level where id = p_employee_id and tenant_id = v_tenant;
  if not found then raise exception 'Employee outside tenant' using errcode = '42501'; end if;
end $$;
revoke all on function public.employee_job_level(uuid) from public;
revoke all on function public.set_employee_job_level(uuid,text) from public;
grant execute on function public.employee_job_level(uuid) to authenticated;
grant execute on function public.set_employee_job_level(uuid,text) to authenticated;
notify pgrst,'reload schema';
commit;
