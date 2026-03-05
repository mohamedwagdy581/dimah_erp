insert into storage.buckets (id, name, public)
values ('employee_photos', 'employee_photos', true)
on conflict (id) do nothing;

-- Path format expected by app:
--   <tenant_id>/<employee_slug>_<employee_id_short>/<employee_slug>.<ext>
-- This keeps files searchable and enforces tenant isolation in policies.

-- Allow public read (bucket is public, but keep explicit policy for clarity).
do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'employee_photos_select_public'
  ) then
    create policy employee_photos_select_public
      on storage.objects
      for select
      using (bucket_id = 'employee_photos');
  end if;
end $$;

-- Allow authenticated users to upload employee photos in their tenant folder.
do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'employee_photos_insert_auth'
  ) then
    create policy employee_photos_insert_auth
      on storage.objects
      for insert
      to authenticated
      with check (
        bucket_id = 'employee_photos'
        and split_part(name, '/', 1) = (
          select u.tenant_id::text
          from public.users u
          where u.id = auth.uid()
        )
      );
  end if;
end $$;

-- Allow authenticated users to update their tenant files.
do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'employee_photos_update_auth'
  ) then
    create policy employee_photos_update_auth
      on storage.objects
      for update
      to authenticated
      using (
        bucket_id = 'employee_photos'
        and split_part(name, '/', 1) = (
          select u.tenant_id::text
          from public.users u
          where u.id = auth.uid()
        )
      )
      with check (
        bucket_id = 'employee_photos'
        and split_part(name, '/', 1) = (
          select u.tenant_id::text
          from public.users u
          where u.id = auth.uid()
        )
      );
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'employee_photos_delete_auth'
  ) then
    create policy employee_photos_delete_auth
      on storage.objects
      for delete
      to authenticated
      using (
        bucket_id = 'employee_photos'
        and split_part(name, '/', 1) = (
          select u.tenant_id::text
          from public.users u
          where u.id = auth.uid()
        )
      );
  end if;
end $$;
