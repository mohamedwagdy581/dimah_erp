alter table public.employees
  add column if not exists photo_url text null;

create index if not exists idx_employees_tenant_photo
  on public.employees (tenant_id)
  where photo_url is not null;
