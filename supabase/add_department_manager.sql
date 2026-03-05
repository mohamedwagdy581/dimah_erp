alter table public.departments
  add column if not exists manager_id uuid null references public.employees(id);

-- If manager_id was previously linked to users(id), convert it to employee_id
-- then switch the foreign key to employees(id).
do $$
declare
  _fk_name text;
begin
  -- Find any FK on departments.manager_id that points to public.users.
  select c.conname
    into _fk_name
  from pg_constraint c
  join pg_class t on t.oid = c.conrelid
  join pg_namespace n on n.oid = t.relnamespace
  join pg_class rt on rt.oid = c.confrelid
  join pg_namespace rn on rn.oid = rt.relnamespace
  where c.contype = 'f'
    and n.nspname = 'public'
    and t.relname = 'departments'
    and rn.nspname = 'public'
    and rt.relname = 'users'
  limit 1;

  if _fk_name is not null then
    -- Map old user ids to employee ids.
    update public.departments d
    set manager_id = u.employee_id
    from public.users u
    where d.manager_id = u.id
      and u.employee_id is not null;

    -- Any remaining values are invalid for employee FK.
    update public.departments d
    set manager_id = null
    where manager_id is not null
      and not exists (
        select 1
        from public.employees e
        where e.id = d.manager_id
      );

    execute format(
      'alter table public.departments drop constraint %I',
      _fk_name
    );
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    join pg_class rt on rt.oid = c.confrelid
    join pg_namespace rn on rn.oid = rt.relnamespace
    where c.contype = 'f'
      and c.conname = 'departments_manager_employee_fk'
      and n.nspname = 'public'
      and t.relname = 'departments'
      and rn.nspname = 'public'
      and rt.relname = 'employees'
  ) then
    alter table public.departments
      add constraint departments_manager_employee_fk
      foreign key (manager_id) references public.employees(id);
  end if;
end $$;

create index if not exists idx_departments_manager
  on public.departments (manager_id);

-- Backfill manager for departments that have no manager yet:
-- 1) prefer employee linked to user role='manager' inside the same department
-- 2) fallback to first active employee in department
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
),
fallback_manager as (
  select distinct on (d.id) d.id as department_id, e.id as employee_id
  from public.departments d
  join public.employees e
    on e.tenant_id = d.tenant_id
   and e.department_id = d.id
   and e.status = 'active'
  order by d.id, e.created_at asc
),
chosen as (
  select d.id as department_id,
         coalesce(pm.employee_id, fm.employee_id) as employee_id
  from public.departments d
  left join preferred_manager pm on pm.department_id = d.id
  left join fallback_manager fm on fm.department_id = d.id
)
update public.departments d
set manager_id = c.employee_id
from chosen c
where d.id = c.department_id
  and d.manager_id is null
  and c.employee_id is not null;
