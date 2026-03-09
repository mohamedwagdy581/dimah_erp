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

alter table public.employee_documents enable row level security;

do $policy$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'employee_documents'
      and policyname = 'employee_documents_select_tenant'
  ) then
    create policy employee_documents_select_tenant
      on public.employee_documents
      for select
      to authenticated
      using (
        tenant_id = (
          select u.tenant_id
          from public.users u
          where u.id = auth.uid()
        )
      );
  end if;
end
$policy$;

do $policy$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'employee_documents'
      and policyname = 'employee_documents_insert_tenant'
  ) then
    create policy employee_documents_insert_tenant
      on public.employee_documents
      for insert
      to authenticated
      with check (
        tenant_id = (
          select u.tenant_id
          from public.users u
          where u.id = auth.uid()
        )
      );
  end if;
end
$policy$;

do $policy$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'employee_documents'
      and policyname = 'employee_documents_update_tenant'
  ) then
    create policy employee_documents_update_tenant
      on public.employee_documents
      for update
      to authenticated
      using (
        tenant_id = (
          select u.tenant_id
          from public.users u
          where u.id = auth.uid()
        )
      )
      with check (
        tenant_id = (
          select u.tenant_id
          from public.users u
          where u.id = auth.uid()
        )
      );
  end if;
end
$policy$;

do $policy$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'employee_documents'
      and policyname = 'employee_documents_delete_tenant'
  ) then
    create policy employee_documents_delete_tenant
      on public.employee_documents
      for delete
      to authenticated
      using (
        tenant_id = (
          select u.tenant_id
          from public.users u
          where u.id = auth.uid()
        )
      );
  end if;
end
$policy$;
