-- Additive installation for the employee portal. No rows are deleted or rewritten.
-- Run once in the project's Supabase SQL Editor after the existing approval workflow.
begin;

create index if not exists idx_attendance_employee_month
  on public.attendance_records (tenant_id, employee_id, date, id);
create index if not exists idx_attendance_pending_correction
  on public.approval_requests (tenant_id, employee_id, (payload ->> 'record_id'))
  where request_type = 'attendance_correction' and status = 'pending';

create or replace function public.employee_attendance_month(p_month date)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  actor public.users%rowtype;
  first_day date;
  next_month date;
  records jsonb;
  pending jsonb;
begin
  select * into actor from public.users where id = auth.uid();
  if not found or actor.role is distinct from 'employee' or actor.is_active is not true or actor.employee_id is null then
    raise exception 'Active linked employee account required' using errcode = '42501';
  end if;
  if not exists (select 1 from public.employees e where e.id = actor.employee_id and e.tenant_id = actor.tenant_id) then
    raise exception 'Invalid employee company link' using errcode = '42501';
  end if;
  if p_month is null then
    raise exception 'Month required' using errcode = '22023';
  end if;
  first_day := pg_catalog.date_trunc('month', p_month::timestamp)::date;
  next_month := (first_day + interval '1 month')::date;
  select coalesce(jsonb_agg(to_jsonb(r) order by r.date desc, r.id), '[]'::jsonb)
    into records from public.attendance_records r
    where r.tenant_id = actor.tenant_id and r.employee_id = actor.employee_id
      and r.date >= first_day and r.date < next_month;
  select coalesce(jsonb_agg(distinct a.payload ->> 'record_id'), '[]'::jsonb)
    into pending from public.approval_requests a
    where a.tenant_id = actor.tenant_id and a.employee_id = actor.employee_id
      and a.request_type = 'attendance_correction' and a.status = 'pending'
      and exists (select 1 from public.attendance_records r
        where r.id::text = a.payload ->> 'record_id' and r.employee_id = actor.employee_id
          and r.tenant_id = actor.tenant_id and r.date >= first_day and r.date < next_month);
  return jsonb_build_object('records', records, 'pending_record_ids', pending);
end;
$$;

create or replace function public.employee_request_attendance_correction(
  p_record_id uuid, p_check_in timestamptz, p_check_out timestamptz, p_reason text
) returns uuid language plpgsql security definer set search_path = ''
as $$
declare
  actor public.users%rowtype;
  attendance public.attendance_records%rowtype;
  existing_id uuid;
  request_id uuid;
  approver text := 'hr';
begin
  select * into actor from public.users where id = auth.uid();
  if not found or actor.role is distinct from 'employee' or actor.is_active is not true or actor.employee_id is null then
    raise exception 'Active linked employee account required' using errcode = '42501';
  end if;
  if p_record_id is null or p_check_in is null or p_check_out is null
     or p_check_out <= p_check_in or nullif(trim(p_reason), '') is null or length(trim(p_reason)) > 500 then
    raise exception 'Valid times and a reason of at most 500 characters required' using errcode = '22023';
  end if;
  -- Serialize competing requests for this record. Lock is released with the transaction.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('attendance-correction:' || p_record_id::text, 0));
  select * into attendance from public.attendance_records
    where id = p_record_id and tenant_id = actor.tenant_id and employee_id = actor.employee_id for share;
  if not found then
    raise exception 'Record is outside your account' using errcode = '42501';
  end if;
  if not exists (select 1 from public.employees e where e.id = actor.employee_id and e.tenant_id = actor.tenant_id) then
    raise exception 'Invalid employee company link' using errcode = '42501';
  end if;
  select id into existing_id from public.approval_requests
    where tenant_id = actor.tenant_id and employee_id = actor.employee_id
      and request_type = 'attendance_correction' and status = 'pending'
      and payload ->> 'record_id' = p_record_id::text order by created_at limit 1;
  -- Network retries return the already pending request instead of submitting twice.
  if existing_id is not null then return existing_id; end if;
  if p_check_in is not distinct from attendance.check_in and p_check_out is not distinct from attendance.check_out then
    raise exception 'At least one recorded time must change' using errcode = '22023';
  end if;
  if exists (
    select 1 from public.employees e left join public.departments d on d.id = e.department_id and d.tenant_id = actor.tenant_id
      join public.users u on u.employee_id = coalesce(e.manager_id, d.manager_id)
        and u.tenant_id = actor.tenant_id and u.role = 'manager' and u.is_active is true
      where e.id = actor.employee_id and e.tenant_id = actor.tenant_id and u.employee_id <> actor.employee_id
  ) then approver := 'manager'; end if;
  insert into public.approval_requests (tenant_id, employee_id, request_type, status, requested_by_role, current_approver_role, payload)
    values (actor.tenant_id, actor.employee_id, 'attendance_correction', 'pending', 'employee', approver,
      jsonb_build_object('record_id', attendance.id, 'date', attendance.date,
        'proposed_check_in', p_check_in, 'proposed_check_out', p_check_out,
        'reason', trim(p_reason), 'original_check_in', attendance.check_in, 'original_check_out', attendance.check_out))
    returning id into request_id;
  return request_id;
end;
$$;

revoke all on function public.employee_attendance_month(date) from public, anon;
revoke all on function public.employee_request_attendance_correction(uuid, timestamptz, timestamptz, text) from public, anon;
grant execute on function public.employee_attendance_month(date) to authenticated;
grant execute on function public.employee_request_attendance_correction(uuid, timestamptz, timestamptz, text) to authenticated;
notify pgrst, 'reload schema';
commit;
