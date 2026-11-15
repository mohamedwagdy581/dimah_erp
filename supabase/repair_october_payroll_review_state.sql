-- Targeted repair for the diagnosed October payroll. Run alone in SQL Editor.
-- Aligns the draft with its existing pending finance approval.
-- Does not change salaries, create approvals, approve payroll or record payment.
begin;
do $repair$
declare
  v_run public.payroll_runs%rowtype;
  v_approval public.approval_requests%rowtype;
  v_count integer;
  v_total numeric;
begin
  select * into v_run from public.payroll_runs
  where id = '16133bfa-0d71-4101-96b3-7162f158836d'::uuid for update;
  if not found then raise exception 'Payroll is missing; nothing changed'; end if;
  select * into v_approval from public.approval_requests
  where id = '930dbd40-979f-4b6d-bbf8-a84031c411ca'::uuid for update;
  if not found then raise exception 'Approval is missing; nothing changed'; end if;
  if v_run.period_start is distinct from date '2026-10-01'
    or v_run.period_end is distinct from date '2026-10-31'
    or v_run.total_employees is distinct from 12
    or v_run.total_amount is distinct from 67200::numeric
    or v_run.tenant_id is distinct from v_approval.tenant_id
    or v_approval.request_type is distinct from 'payroll_run'
    or v_approval.payload ->> 'run_id' is distinct from v_run.id::text
    or v_approval.status is distinct from 'pending'
    or v_approval.current_approver_role is distinct from 'finance_manager'
    or v_run.finance_manager_approved_at is not null
    or v_run.admin_approved_at is not null
    or v_run.disbursement_task_id is not null
    or coalesce(v_run.disbursement_status,'not_started') <> 'not_started' then
    raise exception 'Diagnosed payroll or approval changed; review before repair';
  end if;
  if v_run.status = 'pending_finance_manager' and v_run.hr_approved_at is not null then
    raise notice 'Payroll already ready for finance review';
    return;
  end if;
  if v_run.status is distinct from 'draft' or v_run.hr_approved_at is not null then
    raise exception 'Payroll state changed; nothing changed';
  end if;
  if (select count(*) from public.approval_requests
      where tenant_id = v_run.tenant_id and request_type = 'payroll_run'
        and payload ->> 'run_id' = v_run.id::text and status = 'pending') <> 1 then
    raise exception 'Expected exactly one pending approval; nothing changed';
  end if;
  perform 1 from public.payroll_items where tenant_id = v_run.tenant_id and run_id = v_run.id for update;
  select count(*), coalesce(sum(total_amount),0) into v_count,v_total
  from public.payroll_items where tenant_id = v_run.tenant_id and run_id = v_run.id;
  if v_count <> 12 or round(v_total,2) <> 67200 then
    raise exception 'Salary items differ from diagnosed totals; nothing changed';
  end if;
  update public.payroll_runs
  set status = 'pending_finance_manager', hr_approved_at = v_approval.created_at
  where id = v_run.id and tenant_id = v_run.tenant_id;
end;
$repair$;
select id as run_id,status as payroll_status,hr_approved_at,total_employees,total_amount
from public.payroll_runs where id = '16133bfa-0d71-4101-96b3-7162f158836d'::uuid;
commit;
