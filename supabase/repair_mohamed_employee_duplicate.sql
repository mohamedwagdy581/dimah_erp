-- Targeted repair approved in the conversation: EMP-0013 is the correct record.
-- Run alone in Supabase SQL Editor, then provision login from EMP-0013.
-- Preserves both employee rows and all contracts, financial data and history.
-- Only retires EMP-0004 and replaces its duplicate email with an archive marker.
-- The .invalid domain cannot be used for email delivery. No Auth creation.
begin;

do $repair$
declare
  v_tenant constant uuid := '550e8400-e29b-41d4-a716-446655440000';
  v_keep constant uuid := 'f89b220a-2672-4719-99be-fbe195bfed0a';
  v_old constant uuid := 'b2039a64-4b86-440b-87a6-2a776744aed4';
  v_email constant text := 'mohamedmahrous@dimahmusic.com';
  v_archive_email constant text := 'archived.b2039a64-4b86-440b-87a6-2a776744aed4@employee.invalid';
  v_current public.employees%rowtype;
  v_duplicate public.employees%rowtype;
begin
  -- Same email lock as hr_create_employee_complete. Prevent employee writes
  -- during the short repair, including clients still using the old create RPC.
  perform pg_advisory_xact_lock(hashtextextended(v_email, 1));
  lock table public.employees in share row exclusive mode;

  select * into v_current from public.employees where id = v_keep for update;
  if not found then raise exception 'EMP-0013 is missing; nothing changed'; end if;
  select * into v_duplicate from public.employees where id = v_old for update;
  if not found then raise exception 'EMP-0004 is missing; nothing changed'; end if;

  if v_current.tenant_id is distinct from v_tenant
    or v_duplicate.tenant_id is distinct from v_tenant
    or v_current.employee_number is distinct from 'EMP-0013'
    or v_duplicate.employee_number is distinct from 'EMP-0004'
    or lower(btrim(v_current.email)) is distinct from v_email
    or v_current.status is distinct from 'active' then
    raise exception 'Employee identity or status changed; review before repair';
  end if;

  if exists (select 1 from public.employees
    where lower(btrim(email)) = v_email and id not in (v_keep, v_old)) then
    raise exception 'Another employee has this email; nothing changed';
  end if;

  -- A safe rerun after a successful repair makes no further changes,
  -- including when the correct employee now has an Auth account.
  if v_duplicate.email = v_archive_email and v_duplicate.status = 'inactive' then
    raise notice 'Duplicate already retired; EMP-0013 remains the correct employee';
    return;
  end if;

  if lower(btrim(v_duplicate.email)) is distinct from v_email
    or v_duplicate.status is distinct from 'active' then
    raise exception 'Duplicate record changed; nothing changed';
  end if;
  if exists (select 1 from public.users
    where employee_id in (v_keep, v_old) or lower(btrim(email)) = v_email)
    or exists (select 1 from auth.users where lower(btrim(email)) = v_email) then
    raise exception 'A login account now exists; inspect its link before repair';
  end if;

  if exists (select 1 from public.employees
    where lower(btrim(email)) = v_archive_email and id <> v_old)
    or exists (select 1 from public.users where lower(btrim(email)) = v_archive_email)
    or exists (select 1 from auth.users where lower(btrim(email)) = v_archive_email) then
    raise exception 'Archive email is already in use; nothing changed';
  end if;

  update public.employees set email = v_archive_email, status = 'inactive'
  where id = v_old and tenant_id = v_tenant;
end;
$repair$;

-- Expected: EMP-0013 active with original email; EMP-0004 inactive with archive email.
select id as employee_id, employee_number, full_name, email, status
from public.employees
where tenant_id = '550e8400-e29b-41d4-a716-446655440000'::uuid
  and id in ('f89b220a-2672-4719-99be-fbe195bfed0a'::uuid,
             'b2039a64-4b86-440b-87a6-2a776744aed4'::uuid)
order by employee_number;

commit;
