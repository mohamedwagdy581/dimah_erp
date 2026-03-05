create or replace function public.generate_payroll_run(
  p_tenant_id uuid,
  p_period_start date,
  p_period_end date
)
returns uuid
language plpgsql
security definer
as $$
declare
  v_run_id uuid;
begin
  insert into public.payroll_runs(
    tenant_id,
    period_start,
    period_end,
    status
  )
  values (
    p_tenant_id,
    p_period_start,
    p_period_end,
    'draft'
  )
  returning id into v_run_id;

  insert into public.payroll_items(
    tenant_id,
    run_id,
    employee_id,
    basic_salary,
    housing_allowance,
    transport_allowance,
    other_allowance,
    total_amount
  )
  select
    e.tenant_id,
    v_run_id,
    e.id,
    coalesce(c.basic_salary, 0),
    coalesce(c.housing_allowance, 0),
    coalesce(c.transport_allowance, 0),
    coalesce(c.other_allowance, 0),
    coalesce(c.basic_salary, 0)
      + coalesce(c.housing_allowance, 0)
      + coalesce(c.transport_allowance, 0)
      + coalesce(c.other_allowance, 0)
  from public.employees e
  left join public.employee_compensation c
    on c.employee_id = e.id
  where e.tenant_id = p_tenant_id
    and e.status = 'active';

  update public.payroll_runs
    set total_employees = (
      select count(*) from public.payroll_items where run_id = v_run_id
    ),
    total_amount = (
      select coalesce(sum(total_amount), 0)
      from public.payroll_items
      where run_id = v_run_id
    )
  where id = v_run_id;

  return v_run_id;
end;
$$;
