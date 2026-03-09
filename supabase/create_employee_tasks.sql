create table if not exists public.employee_tasks (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  employee_id uuid not null references public.employees(id),
  assigned_by_employee_id uuid null references public.employees(id),
  title text not null,
  description text null,
  due_date date null,
  task_type text not null default 'general',
  estimate_hours numeric not null default 8 check (estimate_hours > 0 and estimate_hours <= 500),
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  weight int not null default 3 check (weight >= 1 and weight <= 5),
  status text not null default 'todo' check (status in ('todo', 'in_progress', 'done')),
  qa_status text not null default 'pending' check (qa_status in ('pending', 'accepted', 'rework', 'rejected')),
  progress int not null default 0 check (progress >= 0 and progress <= 100),
  assignee_received_at timestamptz null,
  assignee_started_at timestamptz null,
  completed_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.employee_tasks
  add column if not exists task_type text not null default 'general',
  add column if not exists estimate_hours numeric not null default 8,
  add column if not exists priority text not null default 'medium',
  add column if not exists weight int not null default 3,
  add column if not exists qa_status text not null default 'pending',
  add column if not exists assignee_received_at timestamptz null,
  add column if not exists assignee_started_at timestamptz null,
  add column if not exists completed_at timestamptz null;

create index if not exists idx_employee_tasks_tenant_employee
  on public.employee_tasks (tenant_id, employee_id, status);

create index if not exists idx_employee_tasks_tenant_created
  on public.employee_tasks (tenant_id, created_at desc);

create table if not exists public.task_type_weights (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  department_id uuid null references public.departments(id) on delete cascade,
  task_type text not null,
  weight int not null check (weight >= 1 and weight <= 5),
  created_at timestamptz not null default now(),
  unique (tenant_id, department_id, task_type)
);

create index if not exists idx_task_type_weights_tenant_dept
  on public.task_type_weights (tenant_id, department_id, task_type);

-- Global defaults per tenant (used when no department-specific config exists).
insert into public.task_type_weights (tenant_id, department_id, task_type, weight)
select
  t.id,
  null,
  x.task_type,
  x.weight
from public.tenants t
cross join (
  values
    ('general', 3),
    ('transfer', 1),
    ('report', 3),
    ('tax', 5),
    ('payroll', 4),
    ('reconciliation', 4),
    ('recruitment', 3),
    ('employee_docs', 2)
) as x(task_type, weight)
on conflict (tenant_id, department_id, task_type) do nothing;
