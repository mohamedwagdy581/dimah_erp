create table if not exists public.employee_task_attachments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  task_id uuid not null references public.employee_tasks(id) on delete cascade,
  uploaded_by_user_id uuid not null references public.users(id),
  file_name text not null,
  file_url text not null,
  mime_type text null,
  created_at timestamptz not null default now()
);

create index if not exists idx_employee_task_attachments_tenant_task
  on public.employee_task_attachments (tenant_id, task_id, created_at desc);

alter table public.employee_task_attachments enable row level security;

do $policy$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'employee_task_attachments'
      and policyname = 'employee_task_attachments_select_tenant'
  ) then
    create policy employee_task_attachments_select_tenant
      on public.employee_task_attachments
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
      and tablename = 'employee_task_attachments'
      and policyname = 'employee_task_attachments_insert_tenant'
  ) then
    create policy employee_task_attachments_insert_tenant
      on public.employee_task_attachments
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
      and tablename = 'employee_task_attachments'
      and policyname = 'employee_task_attachments_delete_tenant'
  ) then
    create policy employee_task_attachments_delete_tenant
      on public.employee_task_attachments
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

insert into storage.buckets (id, name, public)
values ('task_attachments', 'task_attachments', true)
on conflict (id) do nothing;

update storage.buckets
set public = true
where id = 'task_attachments';

do $policy$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'task_attachments_select_public'
  ) then
    create policy task_attachments_select_public
      on storage.objects
      for select
      using (bucket_id = 'task_attachments');
  end if;
end
$policy$;

do $policy$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'task_attachments_insert_auth'
  ) then
    create policy task_attachments_insert_auth
      on storage.objects
      for insert
      to authenticated
      with check (
        bucket_id = 'task_attachments'
        and split_part(name, '/', 1) = (
          select u.tenant_id::text
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
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'task_attachments_delete_auth'
  ) then
    create policy task_attachments_delete_auth
      on storage.objects
      for delete
      to authenticated
      using (
        bucket_id = 'task_attachments'
        and split_part(name, '/', 1) = (
          select u.tenant_id::text
          from public.users u
          where u.id = auth.uid()
        )
      );
  end if;
end
$policy$;
