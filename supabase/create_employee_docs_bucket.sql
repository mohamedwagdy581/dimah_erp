insert into storage.buckets (id, name, public)
values ('employee_docs', 'employee_docs', true)
on conflict (id) do nothing;

do $policy$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'employee_docs_select_public'
  ) then
    create policy employee_docs_select_public
      on storage.objects
      for select
      using (bucket_id = 'employee_docs');
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
      and policyname = 'employee_docs_insert_auth'
  ) then
    create policy employee_docs_insert_auth
      on storage.objects
      for insert
      to authenticated
      with check (
        bucket_id = 'employee_docs'
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
      and policyname = 'employee_docs_update_auth'
  ) then
    create policy employee_docs_update_auth
      on storage.objects
      for update
      to authenticated
      using (
        bucket_id = 'employee_docs'
        and split_part(name, '/', 1) = (
          select u.tenant_id::text
          from public.users u
          where u.id = auth.uid()
        )
      )
      with check (
        bucket_id = 'employee_docs'
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
      and policyname = 'employee_docs_delete_auth'
  ) then
    create policy employee_docs_delete_auth
      on storage.objects
      for delete
      to authenticated
      using (
        bucket_id = 'employee_docs'
        and split_part(name, '/', 1) = (
          select u.tenant_id::text
          from public.users u
          where u.id = auth.uid()
        )
      );
  end if;
end
$policy$;
