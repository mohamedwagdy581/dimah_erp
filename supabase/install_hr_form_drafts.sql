-- Durable HR form drafts and their save history. No approvals or employee updates.
begin;
create table if not exists public.hr_form_drafts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  created_by uuid not null,
  template_id text not null,
  employee_id uuid references public.employees(id),
  employee_name text,
  data jsonb not null default '{}'::jsonb,
  version integer not null default 1,
  status text not null default 'draft' check (status = 'draft'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (jsonb_typeof(data) = 'object'),
  check (version > 0)
);
create index if not exists hr_form_drafts_owner_updated_idx
  on public.hr_form_drafts(tenant_id,created_by,updated_at desc);
create table if not exists public.hr_form_draft_events (
  id uuid primary key default gen_random_uuid(),
  draft_id uuid not null references public.hr_form_drafts(id),
  version integer not null,
  actor_id uuid not null,
  action text not null check (action in ('created','saved')),
  created_at timestamptz not null default now(),
  unique(draft_id,version)
);
create or replace function public.hr_form_draft_access(p_tenant uuid,p_owner uuid)
returns boolean language sql stable security definer set search_path = public,pg_temp as $$
  select exists(select 1 from public.users where id = auth.uid()
    and id = p_owner and tenant_id = p_tenant and is_active is true and role in ('hr','admin'));
$$;
alter table public.hr_form_drafts enable row level security;
alter table public.hr_form_draft_events enable row level security;
drop policy if exists hr_form_drafts_read on public.hr_form_drafts;
create policy hr_form_drafts_read on public.hr_form_drafts for select to authenticated
  using (public.hr_form_draft_access(tenant_id,created_by));
drop policy if exists hr_form_draft_events_read on public.hr_form_draft_events;
create policy hr_form_draft_events_read on public.hr_form_draft_events for select to authenticated
  using (exists(select 1 from public.hr_form_drafts d where d.id = draft_id
    and public.hr_form_draft_access(d.tenant_id,d.created_by)));
revoke all on public.hr_form_drafts,public.hr_form_draft_events from anon,authenticated;
grant select on public.hr_form_drafts,public.hr_form_draft_events to authenticated;

create or replace function public.hr_save_form_draft(p_template_id text,p_employee_id uuid,
  p_data jsonb,p_id uuid default null,p_expected_version integer default null)
returns public.hr_form_drafts language plpgsql security definer set search_path = public,pg_temp as $$
declare v_tenant uuid; v_name text; v_row public.hr_form_drafts%rowtype; v_new boolean := p_id is null;
begin
  select tenant_id into v_tenant from public.users where id = auth.uid()
    and is_active is true and role in ('hr','admin');
  if v_tenant is null then raise exception 'Active HR/admin required' using errcode = '42501'; end if;
  if p_template_id is null or p_template_id not in ('acknowledgment-prototype','leave-application-prototype',
    'hiring-request','onboarding','probation-review','information-update','transfer-promotion',
    'salary-adjustment','training-request','business-trip','leave-change','overtime-authorization',
    'performance-appraisal','resignation-exit') then raise exception 'Unknown HR template'; end if;
  if p_data is null or jsonb_typeof(p_data) <> 'object' or octet_length(p_data::text) > 262144 then
    raise exception 'Invalid or oversized draft data'; end if;
  if p_employee_id is not null then
    select full_name into v_name from public.employees where id = p_employee_id and tenant_id = v_tenant;
    if not found then raise exception 'Employee outside tenant' using errcode = '42501'; end if;
  end if;
  if v_new then
    insert into public.hr_form_drafts(tenant_id,created_by,template_id,employee_id,employee_name,data)
      values(v_tenant,auth.uid(),p_template_id,p_employee_id,v_name,p_data) returning * into v_row;
  else
    select * into v_row from public.hr_form_drafts where id = p_id
      and tenant_id = v_tenant and created_by = auth.uid() for update;
    if not found then raise exception 'Draft not found' using errcode = '42501'; end if;
    if v_row.template_id <> p_template_id then raise exception 'Draft template cannot change'; end if;
    if p_expected_version is distinct from v_row.version then
      raise exception 'Draft changed in another session; reopen it before saving' using errcode = '40001'; end if;
    update public.hr_form_drafts set employee_id = p_employee_id,employee_name = v_name,data = p_data,
      version = version + 1,updated_at = now() where id = p_id returning * into v_row;
  end if;
  insert into public.hr_form_draft_events(draft_id,version,actor_id,action)
    values(v_row.id,v_row.version,auth.uid(),case when v_new then 'created' else 'saved' end);
  return v_row;
end $$;
revoke all on function public.hr_form_draft_access(uuid,uuid) from public;
grant execute on function public.hr_form_draft_access(uuid,uuid) to authenticated;
revoke all on function public.hr_save_form_draft(text,uuid,jsonb,uuid,integer) from public;
grant execute on function public.hr_save_form_draft(text,uuid,jsonb,uuid,integer) to authenticated;
notify pgrst,'reload schema';
commit;
