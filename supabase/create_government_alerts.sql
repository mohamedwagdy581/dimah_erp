create table if not exists public.government_alerts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  title text not null,
  alert_type text not null,
  description text null,
  start_date date not null,
  end_date date not null,
  file_name text null,
  file_url text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_government_alerts_tenant_end_date
  on public.government_alerts (tenant_id, end_date asc);

alter table public.government_alerts enable row level security;

do $policy$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'government_alerts'
      and policyname = 'government_alerts_select_tenant'
  ) then
    create policy government_alerts_select_tenant
      on public.government_alerts
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
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'government_alerts'
      and policyname = 'government_alerts_insert_tenant'
  ) then
    create policy government_alerts_insert_tenant
      on public.government_alerts
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
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'government_alerts'
      and policyname = 'government_alerts_update_tenant'
  ) then
    create policy government_alerts_update_tenant
      on public.government_alerts
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
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'government_alerts'
      and policyname = 'government_alerts_delete_tenant'
  ) then
    create policy government_alerts_delete_tenant
      on public.government_alerts
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
values ('government_alerts', 'government_alerts', true)
on conflict (id) do nothing;

update storage.buckets
set public = true
where id = 'government_alerts';

do $policy$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'government_alerts_select_public'
  ) then
    create policy government_alerts_select_public
      on storage.objects
      for select
      using (bucket_id = 'government_alerts');
  end if;
end
$policy$;

do $policy$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'government_alerts_insert_auth'
  ) then
    create policy government_alerts_insert_auth
      on storage.objects
      for insert
      to authenticated
      with check (
        bucket_id = 'government_alerts'
        and split_part(name, '/', 1) = (
          select u.tenant_id::text
          from public.users u
          where u.id = auth.uid()
        )
      );
  end if;
end
$policy$;
