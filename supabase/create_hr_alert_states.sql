create table if not exists public.hr_alert_states (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  alert_scope text not null,
  alert_key text not null,
  snooze_until timestamptz null,
  resolved_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, alert_scope, alert_key)
);

create index if not exists idx_hr_alert_states_tenant_scope
  on public.hr_alert_states (tenant_id, alert_scope, updated_at desc);

alter table public.hr_alert_states enable row level security;

do $policy$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'hr_alert_states'
      and policyname = 'hr_alert_states_select_tenant'
  ) then
    create policy hr_alert_states_select_tenant
      on public.hr_alert_states
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
      and tablename = 'hr_alert_states'
      and policyname = 'hr_alert_states_insert_tenant'
  ) then
    create policy hr_alert_states_insert_tenant
      on public.hr_alert_states
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
      and tablename = 'hr_alert_states'
      and policyname = 'hr_alert_states_update_tenant'
  ) then
    create policy hr_alert_states_update_tenant
      on public.hr_alert_states
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
      and tablename = 'hr_alert_states'
      and policyname = 'hr_alert_states_delete_tenant'
  ) then
    create policy hr_alert_states_delete_tenant
      on public.hr_alert_states
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
