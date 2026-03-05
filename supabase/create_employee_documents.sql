create table if not exists public.employee_documents (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  employee_id uuid not null references public.employees(id),
  doc_type text not null,
  file_url text not null,
  issued_at date null,
  expires_at date null,
  created_at timestamptz not null default now()
);

create index if not exists idx_employee_docs_tenant
  on public.employee_documents (tenant_id);

create index if not exists idx_employee_docs_employee
  on public.employee_documents (employee_id);
