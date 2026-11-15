-- Run alone in Supabase SQL Editor before restarting the updated app.
-- Final approval, its approval request and the finance task commit together.
-- Does not change salaries, employee links or account permissions.
begin;

create or replace function public.admin_approve_payroll(p_run_id uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_tenant uuid;
  v_actor_employee uuid;
  v_run public.payroll_runs%rowtype;
  v_approval public.approval_requests%rowtype;
  v_count integer;
  v_item_total numeric;
  v_finance_employee uuid;
  v_reviewer text;
  v_task uuid;
begin
  select u.tenant_id, e.id into v_tenant, v_actor_employee
  from public.users u left join public.employees e
    on e.id = u.employee_id and e.tenant_id = u.tenant_id and e.status = 'active'
  where u.id = auth.uid() and u.is_active is true and u.role = 'admin';
  if v_tenant is null then raise exception 'Active admin required' using errcode = '42501'; end if;

  select * into v_run from public.payroll_runs
  where id = p_run_id and tenant_id = v_tenant for update;
  if not found then raise exception 'Payroll outside tenant' using errcode = '42501'; end if;
  -- Retry after a committed response was lost must not create a second task.
  if v_run.status = 'approved' and v_run.admin_approved_at is not null
    and exists (select 1 from public.employee_tasks
      where id = v_run.disbursement_task_id and tenant_id = v_tenant) then return; end if;
  if v_run.status is distinct from 'pending_admin_approval'
    or v_run.finance_manager_approved_at is null
    or v_run.disbursement_task_id is not null
    or coalesce(v_run.disbursement_status, 'not_started') <> 'not_started' then
    raise exception 'PAYROLL_ADMIN_STATE_CHANGED' using errcode = '40001';
  end if;

  perform 1 from public.approval_requests where tenant_id = v_tenant
    and request_type = 'payroll_run' and payload ->> 'run_id' = p_run_id::text for update;
  select count(*) into v_count from public.approval_requests where tenant_id = v_tenant
    and request_type = 'payroll_run' and payload ->> 'run_id' = p_run_id::text and status = 'pending';
  if v_count <> 1 then raise exception 'PAYROLL_ADMIN_APPROVAL_CONFLICT'; end if;
  select * into v_approval from public.approval_requests where tenant_id = v_tenant
    and request_type = 'payroll_run' and payload ->> 'run_id' = p_run_id::text and status = 'pending';
  if v_approval.current_approver_role is distinct from 'admin' then
    raise exception 'PAYROLL_ADMIN_STATE_CHANGED' using errcode = '40001';
  end if;

  v_reviewer := nullif(v_approval.payload ->> 'finance_reviewed_by', '');
  if v_reviewer is not null then
    -- Return the task to the actual reviewer, never an arbitrary first account.
    select e.id into v_finance_employee from public.users u
    join public.employees e on e.id = u.employee_id and e.tenant_id = u.tenant_id
    where u.id::text = v_reviewer and u.tenant_id = v_tenant
      and u.is_active is true and u.role = 'finance_manager' and e.status = 'active'
    for share of u, e;
    if v_finance_employee is null then raise exception 'PAYROLL_FINANCE_REVIEWER_NOT_LINKED'; end if;
  else
    -- Legacy approvals have no reviewer metadata. Require exactly one eligible manager.
    perform 1 from public.users u join public.employees e
      on e.id = u.employee_id and e.tenant_id = u.tenant_id
      where u.tenant_id = v_tenant and u.role = 'finance_manager'
        and u.is_active is true and e.status = 'active' for share of u, e;
    select count(*) into v_count from public.users u join public.employees e
      on e.id = u.employee_id and e.tenant_id = u.tenant_id
      where u.tenant_id = v_tenant and u.role = 'finance_manager'
        and u.is_active is true and e.status = 'active';
    if v_count = 0 then raise exception 'PAYROLL_FINANCE_MANAGER_NOT_LINKED'; end if;
    if v_count <> 1 then raise exception 'PAYROLL_FINANCE_MANAGER_AMBIGUOUS'; end if;
    select e.id into v_finance_employee from public.users u join public.employees e
      on e.id = u.employee_id and e.tenant_id = u.tenant_id
      where u.tenant_id = v_tenant and u.role = 'finance_manager'
        and u.is_active is true and e.status = 'active';
  end if;

  perform 1 from public.payroll_items where tenant_id = v_tenant and run_id = p_run_id for update;
  select count(*), coalesce(sum(total_amount), 0) into v_count, v_item_total
    from public.payroll_items where tenant_id = v_tenant and run_id = p_run_id;
  if v_count = 0 or v_count is distinct from v_run.total_employees
    or round(v_item_total, 2) is distinct from round(v_run.total_amount, 2) then
    raise exception 'PAYROLL_ADMIN_TOTALS_MISMATCH';
  end if;

  insert into public.employee_tasks(tenant_id, employee_id, assigned_by_employee_id,
    title, description, task_type, estimate_hours, priority, weight, status, progress, due_date)
  values(v_tenant, v_finance_employee, v_actor_employee,
    'Payroll Disbursement ' || v_run.period_start || ' - ' || v_run.period_end,
    'Approved payroll run ' || p_run_id || ' is ready for assignment to an accountant. Bank transfer takes place outside the system.',
    'payroll', 8, 'high', 4, 'todo', 0, current_date + 2) returning id into v_task;

  update public.approval_requests set status = 'approved', reject_reason = null,
    payload = coalesce(payload, '{}'::jsonb) || jsonb_build_object(
      'admin_approved_by', auth.uid(), 'admin_approved_at', now())
    where id = v_approval.id and tenant_id = v_tenant;
  update public.payroll_runs set status = 'approved', admin_approved_at = now(), reject_reason = null,
    disbursement_status = 'assigned_to_finance_manager', disbursement_task_id = v_task,
    disbursement_assignee_employee_id = v_finance_employee
    where id = p_run_id and tenant_id = v_tenant;
end;
$$;
revoke all on function public.admin_approve_payroll(uuid) from public;
grant execute on function public.admin_approve_payroll(uuid) to authenticated;
notify pgrst, 'reload schema';
commit;
