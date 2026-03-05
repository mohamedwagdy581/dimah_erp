create table if not exists public.employee_leave_balance_history (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  employee_id uuid not null references public.employees(id),
  leave_year int not null,
  leave_type text not null check (leave_type in ('annual', 'sick', 'other')),
  days int not null,
  action_type text not null,
  request_id uuid null references public.approval_requests(id),
  leave_id uuid null references public.leave_requests(id),
  actor_user_id uuid null references public.users(id),
  note text null,
  created_at timestamptz not null default now()
);

create index if not exists idx_leave_balance_history_tenant_created
  on public.employee_leave_balance_history (tenant_id, created_at desc);

create index if not exists idx_leave_balance_history_employee_year
  on public.employee_leave_balance_history (employee_id, leave_year);
