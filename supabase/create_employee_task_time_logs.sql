create table if not exists public.employee_task_time_logs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  task_id uuid not null references public.employee_tasks(id) on delete cascade,
  employee_id uuid not null references public.employees(id) on delete cascade,
  logged_by_user_id uuid not null references public.users(id),
  hours numeric not null check (hours > 0 and hours <= 24),
  note text null,
  created_at timestamptz not null default now()
);

create index if not exists idx_employee_task_time_logs_tenant_task
  on public.employee_task_time_logs (tenant_id, task_id, created_at desc);

create index if not exists idx_employee_task_time_logs_tenant_employee
  on public.employee_task_time_logs (tenant_id, employee_id, created_at desc);

alter table public.employee_task_time_logs enable row level security;

do $policy$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'employee_task_time_logs'
      and policyname = 'employee_task_time_logs_select_tenant'
  ) then
    create policy employee_task_time_logs_select_tenant
      on public.employee_task_time_logs
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
      and tablename = 'employee_task_time_logs'
      and policyname = 'employee_task_time_logs_insert_tenant'
  ) then
    create policy employee_task_time_logs_insert_tenant
      on public.employee_task_time_logs
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
      and tablename = 'employee_task_time_logs'
      and policyname = 'employee_task_time_logs_delete_tenant'
  ) then
    create policy employee_task_time_logs_delete_tenant
      on public.employee_task_time_logs
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
