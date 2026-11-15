-- Requires install_attendance_identity.sql. Enables reading verified mappings for CSV preview.
-- Does not import attendance or change any employee mappings.
begin;
create or replace function public.list_employee_attendance_identities()
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare actor public.users%rowtype; result jsonb;
begin
  actor := public.attendance_identity_actor();
  select coalesce(jsonb_agg(jsonb_build_object(
    'employee_id', e.id, 'full_name', e.full_name,
    'device_employee_number', m.device_employee_number
  ) order by e.id), '[]'::jsonb) into result
  from public.employee_attendance_identities m
  join public.employees e on e.id = m.employee_id and e.tenant_id = m.tenant_id
  where m.tenant_id = actor.tenant_id and m.device_key = 'hikvision-main';
  return result;
end;
$$;
revoke all on function public.list_employee_attendance_identities() from public, anon;
grant execute on function public.list_employee_attendance_identities() to authenticated;
notify pgrst, 'reload schema';
commit;
