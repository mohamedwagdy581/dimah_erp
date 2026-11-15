-- Run AFTER install_hr_form_submission.sql in SQL Editor as postgres.
-- Tests real RPCs and eligible existing reviewers; all temporary data rolls back.
-- Sequence numbers may have gaps after rollback (normal PostgreSQL behavior).
begin;
do $test$
declare owner_account public.users%rowtype; employee_row public.employees%rowtype;
  d public.hr_form_drafts%rowtype; again public.hr_form_drafts%rowtype;
  a public.approval_requests%rowtype; reviewer uuid; template text; input jsonb;
  stages integer; changed integer; rejected_id uuid; unauthorized uuid := gen_random_uuid();
begin
  select * into owner_account from public.users where role in ('hr','admin') and is_active is true
    and exists(select 1 from public.users u where u.tenant_id = users.tenant_id and u.role = 'admin' and u.is_active is true)
    order by case role when 'hr' then 0 else 1 end,id limit 1;
  if not found then raise exception 'Test requires active HR/Admin and an active Admin in the same tenant'; end if;
  select * into employee_row from public.employees e where tenant_id = owner_account.tenant_id and status = 'active'
    and not exists(select 1 from public.users u where u.tenant_id = e.tenant_id and u.employee_id = e.id
      and u.role in ('hr','admin') and u.is_active is true) order by id limit 1;
  if not found then raise exception 'Test requires an active employee distinct from HR/Admin reviewers'; end if;
  -- Temporary test balance; both new and existing rows are restored by rollback.
  insert into public.employee_leave_balances(tenant_id,employee_id,leave_year,sick_entitlement,sick_used)
    values(employee_row.tenant_id,employee_row.id,extract(year from current_date)::integer,10,0)
    on conflict(tenant_id,employee_id,leave_year) do update set sick_entitlement = 10,sick_used = 0;

  foreach template in array array['early-exit','leave-application-prototype'] loop
    input := case when template = 'early-exit' then jsonb_build_object('employee_id',employee_row.id,
      'fields',jsonb_build_object('date',current_date,'departure','14:00','shiftEnd','17:00','reason','Rollback integration test'),'checks','{}'::jsonb)
      else jsonb_build_object('employee_id',employee_row.id,'from',current_date,'to',current_date,'leave_type','sick','notes','Rollback integration test') end;
    perform set_config('request.jwt.claim.sub',owner_account.id::text,true);
    perform set_config('request.jwt.claims',jsonb_build_object('sub',owner_account.id,'role','authenticated')::text,true);
    execute 'set local role authenticated';
    select * into d from public.hr_save_form_draft(template,employee_row.id,input);
    select * into d from public.hr_submit_form_draft(d.id,d.version);
    select * into again from public.hr_submit_form_draft(d.id,1);
    if d.status <> 'pending' or again.approval_id <> d.approval_id then raise exception 'Submission retry was not idempotent'; end if;
    begin
      perform public.hr_save_form_draft(template,employee_row.id,input,d.id,d.version);
      raise exception 'Submitted draft must be read-only';
    exception when others then
      if sqlerrm <> 'Submitted forms are read-only' then raise; end if;
    end;
    execute 'reset role';
    if (select count(*) from public.approval_requests where payload->>'hr_draft_id' = d.id::text) <> 1 then raise exception 'Duplicate approval'; end if;
    if (select sick_used from public.employee_leave_balances where tenant_id = employee_row.tenant_id
      and employee_id = employee_row.id and leave_year = extract(year from current_date)::integer) <> 0 then raise exception 'Submission changed the balance'; end if;

    stages := 0;
    while d.status = 'pending' loop
      stages := stages + 1;
      if stages > 3 then raise exception 'Workflow did not finish in three stages'; end if;
      select * into a from public.approval_requests where id = d.approval_id;
      if a.payload->>'hr_form_stage' = 'manager' then reviewer := (a.payload->>'hr_manager_user_id')::uuid;
      else select id into reviewer from public.users where tenant_id = d.tenant_id and role = a.current_approver_role
        and is_active is true and employee_id is distinct from d.employee_id order by id limit 1; end if;
      if reviewer is null then raise exception 'Missing reviewer fixture'; end if;
      perform set_config('request.jwt.claim.sub',unauthorized::text,true);
      perform set_config('request.jwt.claims',jsonb_build_object('sub',unauthorized,'role','authenticated')::text,true);
      execute 'set local role authenticated';
      begin
        perform public.hr_review_form_request(a.id,true);
        raise exception 'Unauthorized review must fail';
      exception when insufficient_privilege then null;
      end;
      execute 'reset role';
      perform set_config('request.jwt.claim.sub',reviewer::text,true);
      perform set_config('request.jwt.claims',jsonb_build_object('sub',reviewer,'role','authenticated')::text,true);
      execute 'set local role authenticated';
      begin
        update public.approval_requests set status = 'approved' where id = a.id;
        get diagnostics changed = row_count;
        if changed > 0 then raise exception 'Direct approval writes must be blocked'; end if;
      exception when insufficient_privilege then null;
      end;
      perform public.hr_review_form_request(a.id,true);
      execute 'reset role';
      select * into d from public.hr_form_drafts where id = d.id;
      if d.status = 'pending' and (select sick_used from public.employee_leave_balances where tenant_id = employee_row.tenant_id
        and employee_id = employee_row.id and leave_year = extract(year from current_date)::integer) <> 0 then raise exception 'Intermediate approval changed balance'; end if;
    end loop;
    if d.status <> 'approved' then raise exception 'Final approval failed'; end if;
    if (select count(*) from public.hr_form_draft_events where draft_id = d.id) <> d.version then raise exception 'Review history missing'; end if;
    if template = 'leave-application-prototype' then
      if (select status from public.leave_requests where hr_form_draft_id = d.id) <> 'approved' then raise exception 'Leave status did not synchronize'; end if;
      if (select sick_used from public.employee_leave_balances where tenant_id = employee_row.tenant_id and employee_id = employee_row.id
        and leave_year = extract(year from current_date)::integer) <> 1 then raise exception 'Final approval must deduct exactly one day'; end if;
      if (select count(*) from public.employee_leave_balance_history where request_id = d.approval_id) <> 1 then raise exception 'Balance history missing/duplicated'; end if;
    end if;
  end loop;

  -- Rejection is terminal and has a mandatory reason.
  perform set_config('request.jwt.claim.sub',owner_account.id::text,true);
  perform set_config('request.jwt.claims',jsonb_build_object('sub',owner_account.id,'role','authenticated')::text,true);
  execute 'set local role authenticated';
  select * into d from public.hr_save_form_draft('early-exit',employee_row.id,
    jsonb_build_object('employee_id',employee_row.id,'fields',jsonb_build_object('date',current_date,'departure','14:00','shiftEnd','17:00','reason','Test rejection')));
  select * into d from public.hr_submit_form_draft(d.id,d.version);
  rejected_id := d.id;
  execute 'reset role';
  select * into a from public.approval_requests where id = d.approval_id;
  if a.payload->>'hr_form_stage' = 'manager' then reviewer := (a.payload->>'hr_manager_user_id')::uuid;
  else select id into reviewer from public.users where tenant_id = d.tenant_id and role = a.current_approver_role
    and is_active is true and employee_id is distinct from d.employee_id order by id limit 1; end if;
  perform set_config('request.jwt.claim.sub',reviewer::text,true);
  perform set_config('request.jwt.claims',jsonb_build_object('sub',reviewer,'role','authenticated')::text,true);
  execute 'set local role authenticated';
  begin
    perform public.hr_review_form_request(a.id,false,'');
    raise exception 'Blank rejection reason must fail';
  exception when others then if sqlerrm <> 'A rejection reason is required' then raise; end if;
  end;
  perform public.hr_review_form_request(a.id,false,'Needs rescheduling');
  execute 'reset role';
  select * into d from public.hr_form_drafts where id = rejected_id;
  if d.status <> 'rejected' or d.reject_reason <> 'Needs rescheduling' then raise exception 'Rejection did not synchronize'; end if;
  raise notice 'HR submission/review checks passed. Temporary drafts, approvals and balances roll back.';
end;
$test$;
rollback;
