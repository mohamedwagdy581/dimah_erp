alter table public.approval_requests
  add column if not exists requested_by_role text null,
  add column if not exists current_approver_role text null,
  add column if not exists approved_by_manager_at timestamptz null,
  add column if not exists approved_by_hr_at timestamptz null,
  add column if not exists approved_by_admin_at timestamptz null;

create index if not exists idx_approval_tenant_current_role
  on public.approval_requests (tenant_id, current_approver_role, status);

update public.approval_requests
set requested_by_role = coalesce(requested_by_role, 'employee')
where requested_by_role is null;

update public.approval_requests
set current_approver_role = coalesce(current_approver_role, 'hr')
where current_approver_role is null and status = 'pending';
