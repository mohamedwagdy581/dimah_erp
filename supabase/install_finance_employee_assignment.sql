-- Finance may assign payment tasks to an active team member with employee/accountant role.
-- Job level never grants permissions. No payroll SELECT access is added for employees.
begin;
create or replace function public.finance_payroll_assignees()
returns jsonb language plpgsql stable security definer set search_path = public, pg_temp as $$
declare v_tenant uuid; v_manager uuid;
begin
  select tenant_id,employee_id into v_tenant,v_manager from public.users
    where id = auth.uid() and role = 'finance_manager' and is_active is true;
  if v_tenant is null or v_manager is null then raise exception 'Linked finance manager required' using errcode = '42501'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('id',e.id,'full_name',e.full_name,
    'employee_number',e.employee_number,'job_level',to_jsonb(e)->>'job_level') order by e.full_name,e.id)
    from public.employees e where e.tenant_id = v_tenant and e.status = 'active' and e.id <> v_manager
      and (e.manager_id = v_manager or exists (select 1 from public.departments d
        where d.id = e.department_id and d.tenant_id = v_tenant and d.manager_id = v_manager))
      and exists (select 1 from public.users u where u.tenant_id = v_tenant and u.employee_id = e.id
        and u.is_active is true and u.role in ('employee','accountant'))),'[]'::jsonb);
end $$;

create or replace function public.finance_assign_payroll(p_run_id uuid,p_employee_id uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_tenant uuid; v_manager uuid; v_run public.payroll_runs%rowtype;
begin
  select tenant_id,employee_id into v_tenant,v_manager from public.users
    where id = auth.uid() and role = 'finance_manager' and is_active is true for share;
  if v_tenant is null or v_manager is null then raise exception 'Linked finance manager required' using errcode = '42501'; end if;
  select * into v_run from public.payroll_runs where id = p_run_id and tenant_id = v_tenant for update;
  if not found then raise exception 'Payroll outside tenant' using errcode = '42501'; end if;
  perform 1 from public.employees e where e.id = p_employee_id and e.tenant_id = v_tenant
    and e.status = 'active' and e.id <> v_manager
    and (e.manager_id = v_manager or exists (select 1 from public.departments d
      where d.id = e.department_id and d.tenant_id = v_tenant and d.manager_id = v_manager))
    and exists (select 1 from public.users u where u.tenant_id = v_tenant and u.employee_id = e.id
      and u.is_active is true and u.role in ('employee','accountant')) for share of e;
  if not found then raise exception 'Active employee/accountant in your team required' using errcode = '42501'; end if;
  if v_run.status = 'approved' and v_run.disbursement_status = 'assigned_to_accountant'
    and v_run.disbursement_assignee_employee_id = p_employee_id
    and exists (select 1 from public.employee_tasks where id = v_run.disbursement_task_id
      and tenant_id = v_tenant and employee_id = p_employee_id and assigned_by_employee_id = v_manager) then return; end if;
  if v_run.status <> 'approved' or v_run.disbursement_status <> 'assigned_to_finance_manager'
    or v_run.disbursement_assignee_employee_id is distinct from v_manager then
    raise exception 'Payroll assignment state changed' using errcode = '40001';
  end if;
  perform 1 from public.employee_tasks where id = v_run.disbursement_task_id
    and tenant_id = v_tenant and employee_id = v_manager and status = 'todo' for update;
  if not found then raise exception 'Finance disbursement task missing or changed'; end if;
  update public.employee_tasks set employee_id = p_employee_id, assigned_by_employee_id = v_manager,
    status = 'todo',progress = 0,qa_status = 'pending',employee_review_status = 'none',
    employee_review_note = null,employee_review_requested_at = null,manager_review_note = null,
    manager_reviewed_at = null,assignee_received_at = null,assignee_started_at = null,
    active_timer_started_at = null,completed_at = null,updated_at = now()
    where id = v_run.disbursement_task_id and tenant_id = v_tenant;
  update public.payroll_runs set disbursement_status = 'assigned_to_accountant',
    disbursement_assignee_employee_id = p_employee_id where id = p_run_id and tenant_id = v_tenant;
end $$;
revoke all on function public.finance_payroll_assignees() from public;
revoke all on function public.finance_assign_payroll(uuid,uuid) from public;
grant execute on function public.finance_payroll_assignees() to authenticated;
grant execute on function public.finance_assign_payroll(uuid,uuid) to authenticated;
notify pgrst,'reload schema';
commit;
