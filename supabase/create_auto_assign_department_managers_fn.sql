create or replace function public.auto_assign_department_managers(
  p_tenant_id uuid
)
returns int
language plpgsql
security definer
as $$
declare
  v_updated int := 0;
begin
  with preferred_manager as (
    select d.id as department_id, e.id as employee_id
    from public.departments d
    join public.employees e
      on e.tenant_id = d.tenant_id
     and e.department_id = d.id
     and e.status = 'active'
    join public.users u
      on u.tenant_id = d.tenant_id
     and u.employee_id = e.id
     and u.role = 'manager'
    where d.tenant_id = p_tenant_id
  ),
  fallback_manager as (
    select distinct on (d.id) d.id as department_id, e.id as employee_id
    from public.departments d
    join public.employees e
      on e.tenant_id = d.tenant_id
     and e.department_id = d.id
     and e.status = 'active'
    where d.tenant_id = p_tenant_id
    order by d.id, e.created_at asc
  ),
  chosen as (
    select d.id as department_id,
           coalesce(pm.employee_id, fm.employee_id) as employee_id
    from public.departments d
    left join preferred_manager pm on pm.department_id = d.id
    left join fallback_manager fm on fm.department_id = d.id
    where d.tenant_id = p_tenant_id
  ),
  updated as (
    update public.departments d
    set manager_id = c.employee_id
    from chosen c
    where d.id = c.department_id
      and c.employee_id is not null
      and (d.manager_id is distinct from c.employee_id)
    returning 1
  )
  select count(*) into v_updated from updated;

  return v_updated;
end;
$$;
