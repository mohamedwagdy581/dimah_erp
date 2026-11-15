-- Run once in Supabase SQL Editor. Preserves existing accounts and roles.
begin;
create table if not exists public.user_access_audit (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  actor_id uuid not null,
  user_id uuid not null,
  old_role text not null,
  new_role text not null,
  old_active boolean not null,
  new_active boolean not null,
  created_at timestamptz not null default now()
);
alter table public.user_access_audit enable row level security;
revoke all on public.user_access_audit from anon, authenticated;

-- Preserve profile edits while preventing direct API updates of account access.
-- SECURITY INVOKER sees the caller's database role; trusted definer functions
-- and service-role provisioning continue to work.
create or replace function public.guard_user_access_columns()
returns trigger language plpgsql security invoker set search_path = public, pg_temp as $$
begin
  if current_user in ('anon', 'authenticated') and (
    new.id is distinct from old.id or new.tenant_id is distinct from old.tenant_id
    or new.employee_id is distinct from old.employee_id
    or new.role is distinct from old.role or new.is_active is distinct from old.is_active
  ) then
    raise exception 'Use authorized account management service' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke all on function public.guard_user_access_columns() from public, anon, authenticated;
drop trigger if exists guard_user_access_columns on public.users;
create trigger guard_user_access_columns before update on public.users
for each row execute function public.guard_user_access_columns();

create or replace function public.list_company_users()
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  actor public.users%rowtype;
  result jsonb;
begin
  select * into actor from public.users where id = auth.uid();
  if not found or actor.is_active is not true or actor.role is null or actor.role not in ('admin', 'hr') then
    raise exception 'Active HR/admin required' using errcode = '42501';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', u.id, 'name', u.name, 'email', u.email, 'role', u.role,
    'is_active', u.is_active, 'employee_id', u.employee_id
  ) order by lower(coalesce(u.name, u.email)), u.id), '[]'::jsonb)
  into result from public.users u where u.tenant_id = actor.tenant_id;
  return jsonb_build_object('actor_id', actor.id, 'can_edit', actor.role = 'admin', 'users', result);
end;
$$;

create or replace function public.admin_update_company_user(
  p_user_id uuid, p_role text, p_active boolean, p_expected_role text, p_expected_active boolean
) returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  actor public.users%rowtype;
  target public.users%rowtype;
begin
  select * into actor from public.users where id = auth.uid();
  if not found or actor.is_active is not true or actor.role is distinct from 'admin' then
    raise exception 'Active system admin required' using errcode = '42501';
  end if;
  if p_user_id is null or p_role is null or p_active is null or p_expected_role is null or p_expected_active is null
    or p_role not in ('employee','manager','direct_manager','hr','accountant','finance_manager','admin') then
    raise exception 'Invalid account values' using errcode = '22023';
  end if;
  -- Serialize changes within the company, then recheck actor access under lock.
  perform 1 from public.tenants where id = actor.tenant_id for update;
  select * into actor from public.users where id = auth.uid() for update;
  if actor.is_active is not true or actor.role is distinct from 'admin' then
    raise exception 'Active system admin required' using errcode = '42501';
  end if;
  if p_user_id = actor.id then
    raise exception 'Cannot change own account access here' using errcode = '42501';
  end if;
  select * into target from public.users where id = p_user_id and tenant_id = actor.tenant_id for update;
  if not found then raise exception 'User outside company' using errcode = '42501'; end if;
  if target.role = p_role and target.is_active = p_active then
    return jsonb_build_object('id', target.id, 'name', target.name, 'email', target.email,
      'role', target.role, 'is_active', target.is_active, 'employee_id', target.employee_id);
  end if;
  if target.role is distinct from p_expected_role or target.is_active is distinct from p_expected_active then
    raise exception 'Account changed; refresh before saving' using errcode = '40001';
  end if;
  if p_role in ('employee','manager','direct_manager') and not exists (
    select 1 from public.employees e where e.id = target.employee_id and e.tenant_id = actor.tenant_id
  ) then raise exception 'Employee/manager role requires linked company employee' using errcode = '22023'; end if;
  if target.role = 'admin' and target.is_active is true and (p_role <> 'admin' or not p_active)
    and (select count(*) from public.users where tenant_id = actor.tenant_id and role = 'admin' and is_active is true) <= 1
    then raise exception 'At least one active admin required' using errcode = '42501'; end if;
  insert into public.user_access_audit(tenant_id, actor_id, user_id, old_role, new_role, old_active, new_active)
    values(actor.tenant_id, actor.id, target.id, target.role, p_role, target.is_active, p_active);
  update public.users set role = p_role, is_active = p_active where id = target.id and tenant_id = actor.tenant_id
    returning * into target;
  return jsonb_build_object('id', target.id, 'name', target.name, 'email', target.email,
    'role', target.role, 'is_active', target.is_active, 'employee_id', target.employee_id);
end;
$$;
revoke all on function public.list_company_users() from public, anon;
revoke all on function public.admin_update_company_user(uuid,text,boolean,text,boolean) from public, anon;
grant execute on function public.list_company_users() to authenticated;
grant execute on function public.admin_update_company_user(uuid,text,boolean,text,boolean) to authenticated;
notify pgrst, 'reload schema';
commit;
