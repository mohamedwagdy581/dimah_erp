-- Requires install_attendance_identity.sql. Install only; no device access here.
-- First release: explicit checkIn/checkOut, Riyadh dates, pairing up to 18 hours.
begin;
create table if not exists public.hikvision_attendance_events (
  tenant_id uuid not null references public.tenants(id),
  device_key text not null,
  serial_number text not null,
  person_number text not null,
  occurred_at timestamptz not null,
  attendance_status text not null,
  received_at timestamptz not null default now(),
  primary key (tenant_id, device_key, serial_number, occurred_at)
);
create index if not exists hikvision_person_time on public.hikvision_attendance_events
  (tenant_id, device_key, person_number, occurred_at);
create table if not exists public.hikvision_attendance_days (
  tenant_id uuid not null,
  device_key text not null,
  employee_id uuid not null references public.employees(id),
  date date not null,
  record_id uuid not null references public.attendance_records(id),
  last_check_in timestamptz,
  last_check_out timestamptz,
  primary key (tenant_id, device_key, employee_id, date)
);
alter table public.hikvision_attendance_events enable row level security;
alter table public.hikvision_attendance_days enable row level security;
revoke all on public.hikvision_attendance_events, public.hikvision_attendance_days from anon, authenticated;

create or replace function public.sync_hikvision_attendance(p_events jsonb)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  actor public.users%rowtype;
  item jsonb; stamp timestamptz; serial text; person text; punch text;
  day_row record; daily public.hikvision_attendance_days%rowtype;
  attendance public.attendance_records%rowtype;
  in_time timestamptz; out_time timestamptz; record_uuid uuid;
  inserted_events integer := 0; changed_days integer := 0; protected_days integer := 0;
  unlinked integer := 0; ignored integer := 0; affected integer;
begin
  actor := public.attendance_identity_actor();
  if jsonb_typeof(p_events) is distinct from 'array' or jsonb_array_length(p_events) > 500 then
    raise exception 'Expected up to 500 events' using errcode = '22023';
  end if;
  -- Serializes bridge retries and concurrent bridge batches for this company/device.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('hikvision-main:' || actor.tenant_id::text, 0));
  for item in select value from jsonb_array_elements(p_events) loop
    serial := item ->> 'serial'; person := item ->> 'person'; punch := item ->> 'status';
    if serial is null or serial !~ '^[0-9]{1,32}$' or person is null
       or person !~ '^[A-Za-z0-9_-]{1,32}$'
       or punch is null or length(punch) > 40
       or coalesce(item ->> 'time', '') !~ '(Z|[+-][0-9]{2}:[0-9]{2})$' then
      raise exception 'Invalid device event' using errcode = '22023';
    end if;
    stamp := (item ->> 'time')::timestamptz;
    if stamp > now() + interval '10 minutes' then
      raise exception 'Device clock is ahead; check device time' using errcode = '22023';
    end if;
    insert into public.hikvision_attendance_events
      (tenant_id, device_key, serial_number, person_number, occurred_at, attendance_status)
    values (actor.tenant_id, 'hikvision-main', serial, person, stamp, punch)
    on conflict do nothing;
    get diagnostics affected = row_count;
    inserted_events := inserted_events + affected;
    if punch not in ('checkIn', 'checkOut') then ignored := ignored + 1; end if;
    if not exists (select 1 from public.employee_attendance_identities m
      where m.tenant_id = actor.tenant_id and m.device_key = 'hikvision-main'
        and m.device_employee_number = person) then unlinked := unlinked + 1; end if;
  end loop;
  -- Replays retained events when a formerly unlinked employee is mapped later.
  -- Limit recomputation to the last 3 days plus dates mentioned in this batch.
  for day_row in
    select distinct m.employee_id, e.person_number,
      (e.occurred_at at time zone 'Asia/Riyadh')::date as work_date
    from public.hikvision_attendance_events e
    join public.employee_attendance_identities m on m.tenant_id = e.tenant_id
      and m.device_key = e.device_key and m.device_employee_number = e.person_number
    join public.employees emp on emp.id = m.employee_id and emp.tenant_id = m.tenant_id
    where e.tenant_id = actor.tenant_id and e.device_key = 'hikvision-main'
      and e.attendance_status = 'checkIn' and emp.status = 'active'
      and (e.occurred_at >= now() - interval '3 days' or
        exists (select 1 from jsonb_array_elements(p_events) x
          where x ->> 'person' = e.person_number and
            abs(extract(epoch from ((x ->> 'time')::timestamptz - e.occurred_at))) <= 129600))
  loop
    select min(e.occurred_at) into in_time from public.hikvision_attendance_events e
      where e.tenant_id = actor.tenant_id and e.device_key = 'hikvision-main'
        and e.person_number = day_row.person_number and e.attendance_status = 'checkIn'
        and (e.occurred_at at time zone 'Asia/Riyadh')::date = day_row.work_date;
    select max(e.occurred_at) into out_time from public.hikvision_attendance_events e
      where e.tenant_id = actor.tenant_id and e.device_key = 'hikvision-main'
        and e.person_number = day_row.person_number and e.attendance_status = 'checkOut'
        and e.occurred_at > in_time and e.occurred_at <= in_time + interval '18 hours'
        and not exists (select 1 from public.hikvision_attendance_events n
          where n.tenant_id = e.tenant_id and n.device_key = e.device_key
            and n.person_number = e.person_number and n.attendance_status = 'checkIn'
            and n.occurred_at > in_time and n.occurred_at < e.occurred_at
            and (n.occurred_at at time zone 'Asia/Riyadh')::date > day_row.work_date);
    perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(
      'attendance-day:' || actor.tenant_id::text || ':' || day_row.employee_id::text || ':' || day_row.work_date::text, 0));
    select * into daily from public.hikvision_attendance_days d where d.tenant_id = actor.tenant_id
      and d.device_key = 'hikvision-main' and d.employee_id = day_row.employee_id and d.date = day_row.work_date;
    if not found then
      -- Preserve CSV imports and manually entered days. Do not merge uncertain sources.
      if exists (select 1 from public.attendance_records r where r.tenant_id = actor.tenant_id
        and r.employee_id = day_row.employee_id and r.date = day_row.work_date) then
        protected_days := protected_days + 1; continue;
      end if;
      insert into public.attendance_records (tenant_id, employee_id, date, status, check_in, check_out, notes)
      values (actor.tenant_id, day_row.employee_id, day_row.work_date, 'present', in_time, out_time,
        'Hikvision automatic sync (hikvision-main)') returning id into record_uuid;
      insert into public.hikvision_attendance_days values
        (actor.tenant_id, 'hikvision-main', day_row.employee_id, day_row.work_date, record_uuid, in_time, out_time);
      changed_days := changed_days + 1;
    else
      perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('attendance-correction:' || daily.record_id::text, 0));
      select * into attendance from public.attendance_records where id = daily.record_id and tenant_id = actor.tenant_id for update;
      if attendance.check_in is distinct from daily.last_check_in or attendance.check_out is distinct from daily.last_check_out
        or attendance.notes is distinct from 'Hikvision automatic sync (hikvision-main)'
        or attendance.status <> 'present'
        or exists (select 1 from public.approval_requests a where a.tenant_id = actor.tenant_id
          and a.employee_id = day_row.employee_id and a.request_type = 'attendance_correction'
          and a.payload ->> 'record_id' = daily.record_id::text) then
        protected_days := protected_days + 1; continue;
      end if;
      if attendance.check_in is distinct from in_time or attendance.check_out is distinct from out_time then
        update public.attendance_records set check_in = in_time, check_out = out_time where id = daily.record_id;
        update public.hikvision_attendance_days set last_check_in = in_time, last_check_out = out_time
          where tenant_id = actor.tenant_id and device_key = 'hikvision-main'
            and employee_id = day_row.employee_id and date = day_row.work_date;
        changed_days := changed_days + 1;
      end if;
    end if;
  end loop;
  return jsonb_build_object('new_events', inserted_events, 'changed_days', changed_days,
    'protected_days', protected_days, 'unlinked_events', unlinked, 'unsupported_events', ignored);
end;
$$;
revoke all on function public.sync_hikvision_attendance(jsonb) from public, anon;
grant execute on function public.sync_hikvision_attendance(jsonb) to authenticated;
notify pgrst, 'reload schema';
commit;
