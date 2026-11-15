-- Read-only team overview for the authenticated finance manager.
-- Preserves data and existing RLS policies. Does not expose personal/bank data.
begin;
create or replace function public.finance_team_overview()
returns jsonb language plpgsql stable security definer
set search_path = public, pg_temp as $function$
declare
  v_tenant uuid;
  v_manager uuid;
begin
  select tenant_id, employee_id into v_tenant, v_manager from public.users
  where id = auth.uid() and is_active is true and role = 'finance_manager';
  if v_tenant is null then raise exception 'Forbidden' using errcode = '42501'; end if;
  if v_manager is null then return '[]'::jsonb; end if;
  return coalesce((select jsonb_agg(jsonb_build_object(
    'id', e.id, 'full_name', e.full_name, 'employee_number', e.employee_number,
    'photo_url', e.photo_url,
    'job_level', to_jsonb(e) ->> 'job_level',
    'job_level', to_jsonb(e) ->> 'job_level',
    'job_title', coalesce(j.name, ''),
    'tasks', coalesce((select jsonb_agg(jsonb_build_object(
      'id', t.id, 'title', t.title, 'status', t.status, 'due_date', t.due_date
    ) order by t.due_date nulls last, t.id) from public.employee_tasks t
      where t.tenant_id = v_tenant and t.employee_id = e.id), '[]'::jsonb)
  ) order by e.full_name, e.id) from public.employees e
  left join public.job_titles j on j.id = e.job_title_id and j.tenant_id = v_tenant
  where e.tenant_id = v_tenant and e.status = 'active' and e.id <> v_manager
    and (e.manager_id = v_manager or exists (
      select 1 from public.departments d where d.id = e.department_id
        and d.tenant_id = v_tenant and d.manager_id = v_manager
    ))), '[]'::jsonb);
end;
$function$;
revoke all on function public.finance_team_overview() from public;
grant execute on function public.finance_team_overview() to authenticated;
notify pgrst, 'reload schema';
commit;
