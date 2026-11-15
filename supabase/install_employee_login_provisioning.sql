-- One-time installation. No new columns, tables or password storage.
-- Only the Edge Function's service role may call these functions.
begin;
create or replace function public.employee_login_context(p_actor_id uuid, p_employee_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor public.users%rowtype;
  emp public.employees%rowtype;
  auth_id uuid;
  app public.users%rowtype;
  matches integer;
begin
  select * into actor from public.users where id = p_actor_id;
  if not found or coalesce(actor.role, '') not in ('admin', 'hr') or actor.is_active is not true then
    raise exception 'Only active HR and admin accounts may provision logins' using errcode = '42501';
  end if;
  select * into emp from public.employees where id = p_employee_id and tenant_id = actor.tenant_id;
  if not found then
    raise exception 'Employee is outside your company or does not exist' using errcode = '42501';
  end if;
  if emp.email is null or trim(emp.email) = '' then
    raise exception 'Employee email is required' using errcode = '22023';
  end if;
  if emp.status = 'inactive' then
    raise exception 'Inactive employee cannot provision login' using errcode = '42501';
  end if;
  select count(*) into matches from public.employees where lower(trim(email)) = lower(trim(emp.email));
  if matches <> 1 then
    raise exception 'Duplicate employee email; resolve duplicate records before provisioning' using errcode = '23505';
  end if;
  select count(*) into matches from auth.users where lower(trim(email)) = lower(trim(emp.email));
  if matches > 1 then
    raise exception 'Multiple Auth accounts match the email' using errcode = '23505';
  end if;
  select id into auth_id from auth.users where lower(trim(email)) = lower(trim(emp.email));
  select * into app from public.users
    where id = auth_id or lower(trim(email)) = lower(trim(emp.email));
  if found then
    if app.id is distinct from auth_id or app.tenant_id is distinct from emp.tenant_id
       or (app.employee_id is not null and app.employee_id <> emp.id)
       or coalesce(app.role, '') not in ('employee', 'manager') then
      raise exception 'Account is already assigned to another employee, company or privileged role' using errcode = '42501';
    end if;
    if exists (select 1 from public.users
      where (id = auth_id or lower(trim(email)) = lower(trim(emp.email))) and id <> app.id) then
      raise exception 'Conflicting application accounts' using errcode = '23505';
    end if;
  end if;
  return jsonb_build_object(
    'employeeId', emp.id, 'tenantId', emp.tenant_id,
    'email', lower(trim(emp.email)), 'name', emp.full_name,
    'authUserId', auth_id
  );
end;
$$;

create or replace function public.complete_employee_login(
  p_actor_id uuid, p_employee_id uuid, p_auth_user_id uuid, p_role text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  context jsonb;
  company_id uuid;
begin
  if p_role not in ('employee', 'manager') or p_role is null then
    raise exception 'Unsupported employee login role' using errcode = '22023';
  end if;
  -- Serialize retries and concurrent requests for this Auth identity.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_auth_user_id::text, 0));
  perform 1 from public.users where id = p_actor_id for update;
  perform 1 from public.employees where id = p_employee_id for update;
  context := public.employee_login_context(p_actor_id, p_employee_id);
  if (context ->> 'authUserId')::uuid is distinct from p_auth_user_id then
    raise exception 'Auth account does not match employee email' using errcode = '42501';
  end if;
  company_id := (context ->> 'tenantId')::uuid;
  insert into public.users (id, tenant_id, email, name, role, employee_id, is_active)
  values (p_auth_user_id, company_id, context ->> 'email', context ->> 'name', p_role, p_employee_id, true)
  on conflict (id) do update set
    email = excluded.email, name = excluded.name,
    role = excluded.role, employee_id = excluded.employee_id, is_active = true;
  return jsonb_build_object('employeeId', p_employee_id, 'email', context ->> 'email', 'role', p_role);
end;
$$;
revoke all on function public.employee_login_context(uuid, uuid) from public, anon, authenticated;
revoke all on function public.complete_employee_login(uuid, uuid, uuid, text) from public, anon, authenticated;
grant execute on function public.employee_login_context(uuid, uuid) to service_role;
grant execute on function public.complete_employee_login(uuid, uuid, uuid, text) to service_role;
commit;
