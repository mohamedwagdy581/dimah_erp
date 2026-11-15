-- Run after install_hr_form_drafts.sql and existing leave/approval installations.
-- Enables Leave Request and Early Exit submission, review and tracking only.
begin;
alter table public.hr_form_drafts drop constraint if exists hr_form_drafts_status_check;
alter table public.hr_form_drafts add constraint hr_form_drafts_status_check
  check(status in ('draft','pending','approved','rejected'));
alter table public.hr_form_drafts add column if not exists approval_id uuid references public.approval_requests(id);
alter table public.hr_form_drafts add column if not exists current_approver_role text;
alter table public.hr_form_drafts add column if not exists reference text;
alter table public.hr_form_drafts add column if not exists reject_reason text;
create unique index if not exists hr_form_drafts_approval_unique on public.hr_form_drafts(approval_id);
create unique index if not exists hr_form_drafts_reference_unique on public.hr_form_drafts(reference);
create sequence if not exists public.hr_form_request_number_seq;
alter table public.hr_form_draft_events drop constraint if exists hr_form_draft_events_action_check;
alter table public.hr_form_draft_events add constraint hr_form_draft_events_action_check
  check(action in ('created','saved','submitted','reviewed','approved','rejected'));
alter table public.hr_form_draft_events add column if not exists actor_role text;
alter table public.hr_form_draft_events add column if not exists note text;
alter table public.leave_requests add column if not exists hr_form_draft_id uuid references public.hr_form_drafts(id);
create unique index if not exists leave_requests_hr_draft_unique on public.leave_requests(hr_form_draft_id);

-- Replaces save RPC to accept the Early Exit form and lock submitted records.
create or replace function public.hr_save_form_draft(p_template_id text,p_employee_id uuid,
  p_data jsonb,p_id uuid default null,p_expected_version integer default null)
returns public.hr_form_drafts language plpgsql security definer set search_path = public,pg_temp as $$
declare v_tenant uuid; v_name text; v_row public.hr_form_drafts%rowtype; v_new boolean := p_id is null;
begin
  select tenant_id into v_tenant from public.users where id = auth.uid()
    and is_active is true and role in ('hr','admin');
  if v_tenant is null then raise exception 'Active HR/admin required' using errcode = '42501'; end if;
  if p_template_id is null or p_template_id not in ('acknowledgment-prototype','leave-application-prototype',
    'hiring-request','onboarding','probation-review','information-update','transfer-promotion',
    'salary-adjustment','training-request','business-trip','leave-change','overtime-authorization',
    'performance-appraisal','resignation-exit','early-exit') then raise exception 'Unknown HR template'; end if;
  if p_data is null or jsonb_typeof(p_data) <> 'object' or octet_length(p_data::text) > 262144 then
    raise exception 'Invalid or oversized draft data'; end if;
  if p_employee_id is not null then
    select full_name into v_name from public.employees where id = p_employee_id and tenant_id = v_tenant;
    if not found then raise exception 'Employee outside tenant' using errcode = '42501'; end if;
  end if;
  if v_new then
    insert into public.hr_form_drafts(tenant_id,created_by,template_id,employee_id,employee_name,data)
      values(v_tenant,auth.uid(),p_template_id,p_employee_id,v_name,p_data) returning * into v_row;
  else
    select * into v_row from public.hr_form_drafts where id = p_id
      and tenant_id = v_tenant and created_by = auth.uid() for update;
    if not found then raise exception 'Draft not found' using errcode = '42501'; end if;
    if v_row.status <> 'draft' then raise exception 'Submitted forms are read-only'; end if;
    if v_row.template_id <> p_template_id then raise exception 'Draft template cannot change'; end if;
    if p_expected_version is distinct from v_row.version then
      raise exception 'Draft changed in another session; reopen it before saving' using errcode = '40001'; end if;
    update public.hr_form_drafts set employee_id = p_employee_id,employee_name = v_name,data = p_data,
      version = version + 1,updated_at = now() where id = p_id returning * into v_row;
  end if;
  insert into public.hr_form_draft_events(draft_id,version,actor_id,action)
    values(v_row.id,v_row.version,auth.uid(),case when v_new then 'created' else 'saved' end);
  return v_row;
end $$;

create or replace function public.hr_submit_form_draft(p_id uuid,p_expected_version integer)
returns public.hr_form_drafts language plpgsql security definer set search_path = public,pg_temp as $$
declare d public.hr_form_drafts%rowtype; actor public.users%rowtype; emp public.employees%rowtype;
  mgr public.users%rowtype; v_manager uuid; v_role text; v_stage text; v_approval uuid; v_leave uuid;
  v_start date; v_end date; v_day date; v_departure time; v_shift_end time; v_type text; v_payload jsonb;
  v_reference text; v_available numeric; v_number bigint;
begin
  select * into actor from public.users where id = auth.uid() and is_active is true and role in ('hr','admin');
  if not found then raise exception 'Active HR/admin required' using errcode = '42501'; end if;
  select * into d from public.hr_form_drafts where id = p_id and tenant_id = actor.tenant_id
    and created_by = actor.id for update;
  if not found then raise exception 'Draft not found' using errcode = '42501'; end if;
  -- Retrying an already submitted record never creates a second approval/leave.
  if d.status <> 'draft' then return d; end if;
  if d.version is distinct from p_expected_version then raise exception 'Draft changed; reopen before submitting' using errcode = '40001'; end if;
  if d.template_id not in ('leave-application-prototype','early-exit') then raise exception 'Submission is not enabled for this template'; end if;
  select * into emp from public.employees where id = d.employee_id and tenant_id = d.tenant_id and status = 'active' for share;
  if not found then raise exception 'Select an active employee'; end if;
  if not exists(select 1 from public.users where tenant_id = d.tenant_id and role = 'admin'
    and is_active is true and employee_id is distinct from emp.id) then raise exception 'No eligible Admin reviewer'; end if;

  v_manager := emp.manager_id;
  if v_manager is null then select manager_id into v_manager from public.departments where id = emp.department_id and tenant_id = d.tenant_id; end if;
  select * into mgr from public.users where tenant_id = d.tenant_id and employee_id = v_manager
    and employee_id <> emp.id and is_active is true and role in ('manager','direct_manager','finance_manager')
    and exists(select 1 from public.employees where id = v_manager and tenant_id = d.tenant_id and status = 'active') order by id limit 1;
  if found then v_role := case when mgr.role = 'direct_manager' then 'manager' else mgr.role end; v_stage := 'manager';
  elsif exists(select 1 from public.users where tenant_id = d.tenant_id and is_active is true and role = 'hr' and employee_id is distinct from emp.id) then
    v_role := 'hr'; v_stage := 'hr';
  else v_role := 'admin'; v_stage := 'admin'; end if;

  v_payload := jsonb_build_object('hr_draft_id',d.id,'hr_form_stage',v_stage,
    'hr_manager_user_id',mgr.id,'form_data',d.data);
  if d.template_id = 'leave-application-prototype' then
    if nullif(d.data->>'from','') is null or nullif(d.data->>'to','') is null then raise exception 'Leave dates are required'; end if;
    v_start := (d.data->>'from')::date; v_end := (d.data->>'to')::date; v_type := d.data->>'leave_type';
    if v_end < v_start then raise exception 'Leave end date must be on or after start'; end if;
    if extract(year from v_start) <> extract(year from v_end) then raise exception 'Split cross-year leave into separate requests'; end if;
    if v_type is null or v_type not in ('annual','sick','unpaid','other') then raise exception 'Invalid leave type'; end if;
    if v_type = 'annual' and (emp.hire_date is null or v_start < (emp.hire_date + interval '11 months')::date
      or (case when extract(year from v_start) < extract(year from now() at time zone 'Asia/Riyadh')
        then make_date(extract(year from v_start)::integer,12,31) else (now() at time zone 'Asia/Riyadh')::date end) < (emp.hire_date + interval '11 months')::date
      or extract(year from v_start) > extract(year from now() at time zone 'Asia/Riyadh')) then
      raise exception 'Annual leave is not yet eligible for this employee/year'; end if;
    if v_type in ('annual','sick','other') then
      select case v_type when 'annual' then annual_entitlement - annual_used when 'sick' then sick_entitlement - sick_used
        else other_entitlement - other_used end into v_available from public.employee_leave_balances
        where tenant_id = d.tenant_id and employee_id = emp.id and leave_year = extract(year from v_start)::integer;
      if not found then v_available := case v_type when 'annual' then 21 when 'sick' then 10 else 5 end; end if;
      if v_end - v_start + 1 > v_available then raise exception 'Insufficient leave balance for submission'; end if;
    end if;
    insert into public.leave_requests(tenant_id,employee_id,type,start_date,end_date,status,notes,leave_year,hr_form_draft_id)
      values(d.tenant_id,emp.id,v_type,v_start,v_end,'pending',nullif(btrim(d.data->>'notes'),''),extract(year from v_start)::integer,d.id)
      returning id into v_leave;
    v_payload := v_payload || jsonb_build_object('leave_id',v_leave,'type',v_type,'start_date',v_start,
      'end_date',v_end,'leave_year',extract(year from v_start)::integer,'notes',d.data->>'notes');
  else
    if nullif(d.data #>> '{fields,date}','') is null or nullif(d.data #>> '{fields,departure}','') is null
      or nullif(d.data #>> '{fields,shiftEnd}','') is null or nullif(btrim(d.data #>> '{fields,reason}'),'') is null then
      raise exception 'Early Exit date, times and reason are required'; end if;
    v_day := replace(d.data #>> '{fields,date}','/','-')::date;
    v_departure := (d.data #>> '{fields,departure}')::time;
    v_shift_end := (d.data #>> '{fields,shiftEnd}')::time;
    if v_departure >= v_shift_end then raise exception 'Departure must be earlier than shift end (same day)'; end if;
    v_payload := v_payload || jsonb_build_object('date',v_day,'departure',v_departure,'shift_end',v_shift_end,'notes',d.data #>> '{fields,reason}');
  end if;
  v_number := nextval('public.hr_form_request_number_seq');
  v_reference := 'HR-'||to_char(now() at time zone 'Asia/Riyadh','YYYY')||'-'||lpad(v_number::text,greatest(6,length(v_number::text)),'0');
  v_payload := v_payload || jsonb_build_object('reference',v_reference);
  insert into public.approval_requests(tenant_id,employee_id,request_type,status,requested_by_role,current_approver_role,payload)
    values(d.tenant_id,emp.id,case when d.template_id = 'early-exit' then 'early_exit' else 'leave' end,
      'pending',actor.role,v_role,v_payload) returning id into v_approval;
  update public.hr_form_drafts set status = 'pending',approval_id = v_approval,current_approver_role = v_role,
    reference = v_reference,version = version + 1,updated_at = now() where id = d.id returning * into d;
  insert into public.hr_form_draft_events(draft_id,version,actor_id,actor_role,action,note)
    values(d.id,d.version,actor.id,actor.role,'submitted',v_role);
  return d;
end $$;

create or replace function public.hr_review_form_request(p_request_id uuid,p_approve boolean,p_reason text default null)
returns void language plpgsql security definer set search_path = public,pg_temp as $$
declare actor public.users%rowtype; a public.approval_requests%rowtype; d public.hr_form_drafts%rowtype;
  l public.leave_requests%rowtype; b public.employee_leave_balances%rowtype;
  v_role text; v_stage text; v_next text; v_status text; v_days integer; v_available numeric;
begin
  if p_approve is null then raise exception 'Decision required'; end if;
  select * into actor from public.users where id = auth.uid() and is_active is true;
  if not found then raise exception 'Active reviewer required' using errcode = '42501'; end if;
  -- Same draft-then-approval lock order as submission.
  select * into d from public.hr_form_drafts where approval_id = p_request_id and tenant_id = actor.tenant_id for update;
  if not found then raise exception 'HR form request not found' using errcode = '42501'; end if;
  select * into a from public.approval_requests where id = p_request_id and tenant_id = d.tenant_id for update;
  if not found or a.payload->>'hr_draft_id' is distinct from d.id::text or a.employee_id is distinct from d.employee_id then raise exception 'Broken HR approval link'; end if;
  v_role := case when actor.role = 'direct_manager' then 'manager' else actor.role end;
  v_stage := a.payload->>'hr_form_stage';
  if a.status <> 'pending' or d.status <> 'pending' then raise exception 'Request is no longer pending'; end if;
  if actor.employee_id = d.employee_id or v_role is distinct from a.current_approver_role
    or v_role not in ('manager','finance_manager','hr','admin')
    or (v_stage = 'manager' and a.payload->>'hr_manager_user_id' is distinct from actor.id::text) then
    raise exception 'Request is not assigned to this reviewer' using errcode = '42501'; end if;
  if not p_approve and nullif(btrim(p_reason),'') is null then raise exception 'A rejection reason is required'; end if;
  if not p_approve then v_status := 'rejected'; v_next := null;
  elsif v_stage = 'manager' and exists(select 1 from public.users where tenant_id = d.tenant_id
    and role = 'hr' and is_active is true and employee_id is distinct from d.employee_id) then v_status := 'pending'; v_next := 'hr';
  elsif v_stage in ('manager','hr') then v_status := 'pending'; v_next := 'admin';
  elsif v_stage = 'admin' and v_role = 'admin' then v_status := 'approved'; v_next := null;
  else raise exception 'Invalid review stage'; end if;
  if v_next is not null and not exists(select 1 from public.users where tenant_id = d.tenant_id
    and role = v_next and is_active is true and employee_id is distinct from d.employee_id) then
    raise exception 'No eligible next reviewer'; end if;

  if d.template_id = 'leave-application-prototype' then
    select * into l from public.leave_requests where hr_form_draft_id = d.id and tenant_id = d.tenant_id for update;
    if not found or l.id::text is distinct from a.payload->>'leave_id' or l.status <> 'pending' then raise exception 'Leave is no longer pending'; end if;
    if v_status = 'approved' and l.type in ('annual','sick','other') then
      insert into public.employee_leave_balances(tenant_id,employee_id,leave_year)
        values(l.tenant_id,l.employee_id,l.leave_year) on conflict(tenant_id,employee_id,leave_year) do nothing;
      select * into b from public.employee_leave_balances where tenant_id = l.tenant_id and employee_id = l.employee_id and leave_year = l.leave_year for update;
      v_days := l.end_date - l.start_date + 1;
      v_available := case l.type when 'annual' then b.annual_entitlement - b.annual_used when 'sick' then b.sick_entitlement - b.sick_used else b.other_entitlement - b.other_used end;
      if v_days > v_available then raise exception 'Insufficient leave balance at final approval'; end if;
      update public.employee_leave_balances set annual_used = annual_used + case when l.type = 'annual' then v_days else 0 end,
        sick_used = sick_used + case when l.type = 'sick' then v_days else 0 end,
        other_used = other_used + case when l.type = 'other' then v_days else 0 end where id = b.id;
      insert into public.employee_leave_balance_history(tenant_id,employee_id,leave_year,leave_type,days,action_type,request_id,leave_id,actor_user_id,note)
        values(l.tenant_id,l.employee_id,l.leave_year,l.type,v_days,'approve',a.id,l.id,actor.id,'HR form final approval');
    end if;
    if v_status <> 'pending' then update public.leave_requests set status = v_status where id = l.id; end if;
  end if;
  update public.approval_requests set status = v_status,current_approver_role = v_next,
    reject_reason = case when not p_approve then btrim(p_reason) else null end,
    payload = payload || jsonb_build_object('hr_form_stage',coalesce(v_next,v_stage)),
    approved_by_manager_at = case when p_approve and v_stage = 'manager' then now() else approved_by_manager_at end,
    approved_by_hr_at = case when p_approve and v_stage = 'hr' then now() else approved_by_hr_at end,
    approved_by_admin_at = case when p_approve and v_stage = 'admin' then now() else approved_by_admin_at end where id = a.id;
  update public.hr_form_drafts set status = v_status,current_approver_role = v_next,
    reject_reason = case when not p_approve then btrim(p_reason) else null end,
    version = version + 1,updated_at = now() where id = d.id returning * into d;
  insert into public.hr_form_draft_events(draft_id,version,actor_id,actor_role,action,note)
    values(d.id,d.version,actor.id,v_role,case when v_status = 'pending' then 'reviewed' else v_status end,
      case when not p_approve then btrim(p_reason) else v_next end);
end $$;

-- Permit only server-owned workflow functions to write linked approvals/leaves,
-- even when legacy approval table policies allow direct client updates.
create or replace function public.hr_form_workflow_write_guard()
returns trigger language plpgsql set search_path = public,pg_temp as $$
declare linked boolean;
begin
  if tg_table_name = 'approval_requests' then
    linked := (tg_op <> 'INSERT' and old.payload ? 'hr_draft_id') or (tg_op <> 'DELETE' and new.payload ? 'hr_draft_id');
  else
    linked := (tg_op <> 'INSERT' and old.hr_form_draft_id is not null) or (tg_op <> 'DELETE' and new.hr_form_draft_id is not null);
  end if;
  if linked and current_user not in ('postgres','supabase_admin') then
    raise exception 'Use the HR form workflow RPC' using errcode = '42501'; end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end $$;
drop trigger if exists hr_form_approval_write_guard on public.approval_requests;
create trigger hr_form_approval_write_guard before insert or update or delete on public.approval_requests
  for each row execute function public.hr_form_workflow_write_guard();
drop trigger if exists hr_form_leave_write_guard on public.leave_requests;
create trigger hr_form_leave_write_guard before insert or update or delete on public.leave_requests
  for each row execute function public.hr_form_workflow_write_guard();
revoke all on function public.hr_form_workflow_write_guard() from public;
create or replace function public.hr_form_approval_read(p_request_id uuid)
returns boolean language sql stable security definer set search_path = public,pg_temp as $$
  select exists(select 1 from public.hr_form_drafts d join public.approval_requests a on a.id = d.approval_id
    join public.users u on u.id = auth.uid() and u.tenant_id = d.tenant_id and u.is_active is true
    where a.id = p_request_id and a.tenant_id = d.tenant_id and
    (u.role in ('hr','admin') or (u.role in ('manager','direct_manager','finance_manager')
      and a.payload->>'hr_manager_user_id' = u.id::text)));
$$;
revoke all on function public.hr_form_approval_read(uuid) from public;
grant execute on function public.hr_form_approval_read(uuid) to authenticated;
drop policy if exists hr_form_approval_read on public.approval_requests;
create policy hr_form_approval_read on public.approval_requests for select to authenticated
  using(public.hr_form_approval_read(id));
revoke all on function public.hr_submit_form_draft(uuid,integer) from public;
revoke all on function public.hr_review_form_request(uuid,boolean,text) from public;
grant execute on function public.hr_submit_form_draft(uuid,integer) to authenticated;
grant execute on function public.hr_review_form_request(uuid,boolean,text) to authenticated;
notify pgrst,'reload schema';
commit;
