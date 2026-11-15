-- Read-only pre-installation checks. Run in Supabase SQL Editor.
select column_name, data_type from information_schema.columns
where table_schema = 'public' and table_name in ('attendance_records', 'approval_requests')
order by table_name, ordinal_position;

select tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies where schemaname = 'public' and tablename in ('attendance_records', 'approval_requests');

select relname, relrowsecurity from pg_class join pg_namespace n on n.oid = relnamespace
where n.nspname = 'public' and relname in ('attendance_records', 'approval_requests');

select tenant_id, employee_id, date, count(*) as record_count
from public.attendance_records group by tenant_id, employee_id, date having count(*) > 1;

select id, date, check_in, check_out from public.attendance_records
where check_in is not null and check_out is not null and check_out < check_in;

select tenant_id, employee_id, payload ->> 'record_id' as record_id, count(*)
from public.approval_requests where request_type = 'attendance_correction' and status = 'pending'
group by tenant_id, employee_id, payload ->> 'record_id' having count(*) > 1;
