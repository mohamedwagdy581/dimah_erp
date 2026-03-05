alter table public.leave_requests
  add column if not exists leave_year int;

update public.leave_requests
set leave_year = extract(year from start_date)::int
where leave_year is null;

create table if not exists public.employee_leave_balances (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  employee_id uuid not null references public.employees(id),
  leave_year int not null,
  annual_entitlement numeric not null default 21,
  sick_entitlement numeric not null default 10,
  other_entitlement numeric not null default 5,
  annual_used numeric not null default 0,
  sick_used numeric not null default 0,
  other_used numeric not null default 0,
  created_at timestamptz not null default now(),
  unique (tenant_id, employee_id, leave_year)
);

create index if not exists idx_leave_balance_tenant_year
  on public.employee_leave_balances (tenant_id, leave_year);

create index if not exists idx_leave_balance_employee_year
  on public.employee_leave_balances (employee_id, leave_year);

insert into public.employee_leave_balances (
  tenant_id, employee_id, leave_year
)
select e.tenant_id, e.id, extract(year from current_date)::int
from public.employees e
left join public.employee_leave_balances b
  on b.tenant_id = e.tenant_id
 and b.employee_id = e.id
 and b.leave_year = extract(year from current_date)::int
where b.id is null;
