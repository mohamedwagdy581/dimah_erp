-- Run once in Supabase SQL editor. Keeps existing payroll rows and approvals.
-- Finance review and its notes are committed together, or rolled back together.
begin;
create or replace function public.finance_review_payroll(
  p_run_id uuid, p_approve boolean, p_notes text default null
) returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_tenant uuid;
  v_run public.payroll_runs%rowtype;
  v_notes text := nullif(btrim(p_notes), '');
  v_count integer;
  v_item_count integer;
  v_item_total numeric;
begin
  select u.tenant_id into v_tenant from public.users u
  where u.id = auth.uid() and u.is_active is true and u.role = 'finance_manager';
  if v_tenant is null then raise exception 'Active finance manager required' using errcode = '42501'; end if;
  if p_run_id is null or p_approve is null or length(coalesce(v_notes, '')) > 500
    or (not p_approve and v_notes is null) then raise exception 'Invalid payroll review'; end if;
  select * into v_run from public.payroll_runs where id = p_run_id and tenant_id = v_tenant for update;
  if not found then raise exception 'Payroll outside tenant' using errcode = '42501'; end if;
  if v_run.status <> 'pending_finance_manager' then
    raise exception 'Payroll review state changed; reload the payroll' using errcode = '40001';
  end if;
  select count(*), coalesce(sum(total_amount), 0) into v_item_count, v_item_total
  from public.payroll_items where run_id = p_run_id and tenant_id = v_tenant;
  if p_approve and (v_item_count = 0 or v_item_count <> v_run.total_employees
    or round(v_item_total, 2) <> round(v_run.total_amount, 2)) then
    raise exception 'Payroll items do not match recorded totals';
  end if;
  update public.approval_requests
  set current_approver_role = case when p_approve then 'admin' else current_approver_role end,
      status = case when p_approve then 'pending' else 'rejected' end,
      reject_reason = case when p_approve then null else v_notes end,
      payload = coalesce(payload, '{}'::jsonb) || jsonb_build_object(
        'finance_review_notes', v_notes, 'finance_reviewed_by', auth.uid(), 'finance_reviewed_at', now())
  where tenant_id = v_tenant and request_type = 'payroll_run'
    and payload @> jsonb_build_object('run_id', p_run_id::text)
    and status = 'pending' and current_approver_role = 'finance_manager';
  get diagnostics v_count = row_count;
  if v_count = 0 then raise exception 'Pending finance approval request not found'; end if;
  update public.payroll_runs
  set status = case when p_approve then 'pending_admin_approval' else 'rejected_by_finance_manager' end,
      finance_manager_approved_at = case when p_approve then now() else finance_manager_approved_at end,
      reject_reason = case when p_approve then null else v_notes end
  where id = p_run_id and tenant_id = v_tenant;
end;
$$;
revoke all on function public.finance_review_payroll(uuid,boolean,text) from public;
grant execute on function public.finance_review_payroll(uuid,boolean,text) to authenticated;
notify pgrst, 'reload schema';
commit;
