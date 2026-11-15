-- Requires install_attendance_identity.sql. Installs an opt-in repair RPC only.
-- No records change until HR/admin reimports the original CSV with repair enabled.
begin;
create or replace function public.repair_imported_attendance_timezone(
  p_record_id uuid, p_check_in timestamptz, p_check_out timestamptz,
  p_source_notes text
)
returns text language plpgsql security definer set search_path = ''
as $$
declare
  actor public.users%rowtype;
  attendance public.attendance_records%rowtype;
  expected_notes text;
begin
  actor := public.attendance_identity_actor();
  if p_record_id is null or (p_check_in is null and p_check_out is null)
     or (p_check_in is not null and p_check_out is not null and p_check_out <= p_check_in) then
    raise exception 'Invalid attendance times' using errcode = '22023';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('attendance-correction:' || p_record_id::text, 0));
  select * into attendance from public.attendance_records
    where id = p_record_id and tenant_id = actor.tenant_id for update;
  if not found then
    raise exception 'Attendance does not belong to your company' using errcode = '42501';
  end if;
  select 'Imported from biometric CSV (Person ID: ' || m.device_employee_number || ')'
    into expected_notes
    from public.employee_attendance_identities m
    join public.employees e on e.id = m.employee_id and e.tenant_id = m.tenant_id
    where m.tenant_id = actor.tenant_id and m.employee_id = attendance.employee_id
      and m.device_key = 'hikvision-main';
  if expected_notes is null or attendance.notes is distinct from expected_notes
     or p_source_notes is distinct from expected_notes then return 'skipped_source'; end if;
  if exists (select 1 from public.approval_requests a
    where a.tenant_id = actor.tenant_id and a.employee_id = attendance.employee_id
      and a.request_type = 'attendance_correction'
      and a.payload ->> 'record_id' = attendance.id::text) then return 'skipped_correction'; end if;
  if (coalesce(p_check_in, p_check_out) at time zone 'Asia/Riyadh')::date <> attendance.date then
    return 'skipped_date';
  end if;
  if attendance.check_in is not distinct from p_check_in
     and attendance.check_out is not distinct from p_check_out then return 'unchanged'; end if;
  -- Repair only the exact known +3-hour error, never overwrite arbitrary edits.
  if attendance.check_in is distinct from (p_check_in + interval '3 hours')
     or attendance.check_out is distinct from (p_check_out + interval '3 hours') then
    return 'skipped_times';
  end if;
  update public.attendance_records set check_in = p_check_in, check_out = p_check_out
    where id = attendance.id and tenant_id = actor.tenant_id;
  return 'repaired';
end;
$$;
revoke all on function public.repair_imported_attendance_timezone(uuid, timestamptz, timestamptz, text) from public, anon;
grant execute on function public.repair_imported_attendance_timezone(uuid, timestamptz, timestamptz, text) to authenticated;
notify pgrst, 'reload schema';
commit;
