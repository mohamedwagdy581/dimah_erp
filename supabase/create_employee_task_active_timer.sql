alter table public.employee_tasks
  add column if not exists active_timer_started_at timestamptz null;
