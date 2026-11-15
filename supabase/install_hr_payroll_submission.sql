-- Install before running the updated app. Existing payroll and approvals stay intact.
-- HR submission changes payroll and its finance approval in one transaction.
begin;
create or replace function public.hr_submit_payroll(p_run_id uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_tenant uuid;
  v_actor_employee uuid;
  v_requester uuid;
  v_run public.payroll_runs%rowtype;
  v_pending public.approval_requests%rowtype;
  v_pending_count integer;
  v_item_count integer;
  v_item_total numeric;
begin
  select tenant_id,employee_id into v_tenant,v_actor_employee from public.users
  where id = auth.uid() and is_active is true and role in ('hr','admin');
  if v_tenant is null then raise exception 'Active HR/admin required' using errcode = '42501'; end if;
  select * into v_run from public.payroll_runs
  where id = p_run_id and tenant_id = v_tenant for update;
  if not found then raise exception 'Payroll outside tenant' using errcode = '42501'; end if;
  if v_run.status not in ('draft','rejected_by_finance_manager','rejected_by_admin','pending_finance_manager')
    or v_run.disbursement_task_id is not null
    or coalesce(v_run.disbursement_status,'not_started') <> 'not_started' then
    raise exception 'Payroll cannot be submitted in its current state' using errcode = '40001';
  end if;
  perform 1 from public.payroll_items where tenant_id = v_tenant and run_id = p_run_id for update;
  select count(*),coalesce(sum(total_amount),0) into v_item_count,v_item_total
  from public.payroll_items where tenant_id = v_tenant and run_id = p_run_id;
  if v_item_count = 0 or v_item_count <> v_run.total_employees
    or round(v_item_total,2) <> round(v_run.total_amount,2) then
    raise exception 'Payroll items do not match recorded totals';
  end if;
  perform 1 from public.approval_requests where tenant_id = v_tenant
    and request_type = 'payroll_run' and payload ->> 'run_id' = p_run_id::text for update;
  select count(*) into v_pending_count from public.approval_requests where tenant_id = v_tenant
    and request_type = 'payroll_run' and payload ->> 'run_id' = p_run_id::text and status = 'pending';
  if v_pending_count > 1 then raise exception 'Multiple pending payroll approvals'; end if;
  if v_pending_count = 1 then
    select * into v_pending from public.approval_requests where tenant_id = v_tenant
      and request_type = 'payroll_run' and payload ->> 'run_id' = p_run_id::text and status = 'pending';
    if v_pending.current_approver_role is distinct from 'finance_manager' then
      raise exception 'Payroll approval is assigned to another stage' using errcode = '40001';
    end if;
    if v_run.status = 'pending_finance_manager' then return; end if;
    if v_run.status <> 'draft' then raise exception 'Rejected payroll has a conflicting pending approval'; end if;
  else
    select id into v_requester from public.employees
    where id = v_actor_employee and tenant_id = v_tenant and status = 'active';
    if v_requester is null then
      select e.id into v_requester from public.users u
      join public.employees e on e.id = u.employee_id and e.tenant_id = u.tenant_id
      where u.tenant_id = v_tenant and u.role = 'hr' and u.is_active is true and e.status = 'active'
      order by u.id limit 1;
    end if;
    if v_requester is null then raise exception 'Active HR requester employee profile required'; end if;
    insert into public.approval_requests(tenant_id,request_type,employee_id,status,payload,requested_by_role,current_approver_role)
    values(v_tenant,'payroll_run',v_requester,'pending',jsonb_build_object('run_id',p_run_id::text),'hr','finance_manager');
  end if;
  update public.payroll_runs set status = 'pending_finance_manager',reject_reason = null,
    hr_approved_at = coalesce(v_pending.created_at,now()),finance_manager_approved_at = null,admin_approved_at = null
  where id = p_run_id and tenant_id = v_tenant;
end;
$$;
revoke all on function public.hr_submit_payroll(uuid) from public;
grant execute on function public.hr_submit_payroll(uuid) to authenticated;
notify pgrst,'reload schema';
commit;
