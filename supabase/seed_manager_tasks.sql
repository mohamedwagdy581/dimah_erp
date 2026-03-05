-- Seed starter tasks for manager teams.
-- Safe to run multiple times: only inserts for employees with no tasks yet.

with team_members as (
  select
    m.tenant_id,
    m.id as manager_employee_id,
    e.id as employee_id
  from public.employees m
  join public.users u
    on u.tenant_id = m.tenant_id
   and u.employee_id = m.id
   and u.role = 'manager'
  join public.employees e
    on e.tenant_id = m.tenant_id
   and e.manager_id = m.id
   and e.status = 'active'
),
no_tasks_yet as (
  select tm.*
  from team_members tm
  where not exists (
    select 1
    from public.employee_tasks t
    where t.tenant_id = tm.tenant_id
      and t.employee_id = tm.employee_id
  )
)
insert into public.employee_tasks (
  tenant_id,
  employee_id,
  assigned_by_employee_id,
  title,
  description,
  due_date,
  status,
  progress
)
select
  n.tenant_id,
  n.employee_id,
  n.manager_employee_id,
  v.title,
  v.description,
  (current_date + v.days_offset)::date,
  'todo',
  0
from no_tasks_yet n
cross join (
  values
    ('Submit Weekly Plan', 'Prepare and submit your weekly execution plan.', 3),
    ('Update KPI Sheet', 'Update KPI sheet and mark blockers if any.', 5)
) as v(title, description, days_offset);
