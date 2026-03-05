create table if not exists public.approval_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  request_type text not null, -- leave / attendance_correction
  employee_id uuid not null references public.employees(id),
  status text not null default 'pending',
  payload jsonb null,
  reject_reason text null,
  created_at timestamptz not null default now()
);

create index if not exists idx_approval_tenant_status
  on public.approval_requests (tenant_id, status);
