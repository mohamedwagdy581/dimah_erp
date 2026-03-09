create table if not exists public.employee_task_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  task_id uuid not null references public.employee_tasks(id) on delete cascade,
  event_type text not null,
  event_note text null,
  event_payload jsonb not null default '{}'::jsonb,
  created_by_user_id uuid null references public.users(id),
  created_at timestamptz not null default now()
);

create index if not exists idx_employee_task_events_tenant_task
  on public.employee_task_events (tenant_id, task_id, created_at desc);

alter table public.employee_tasks
  add column if not exists assignee_received_at timestamptz null,
  add column if not exists assignee_started_at timestamptz null;
