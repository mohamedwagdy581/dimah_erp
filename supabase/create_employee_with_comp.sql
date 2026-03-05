create or replace function public.create_employee_with_comp(
  p_tenant_id uuid,
  p_full_name text,
  p_email text,
  p_phone text,
  p_national_id text,
  p_department_id uuid,
  p_job_title_id uuid,
  p_hire_date date,
  p_employment_type text,
  p_basic_salary numeric,
  p_housing_allowance numeric,
  p_transport_allowance numeric,
  p_other_allowance numeric,
  p_contract_type text,
  p_contract_start date,
  p_contract_end date default null,
  p_probation_months int default null,
  p_contract_file_url text default null,
  p_photo_url text default null,
  p_date_of_birth date default null,
  p_gender text default null,
  p_nationality text default null,
  p_education text default null,
  p_national_id_expiry date default null,
  p_notes text default null,
  p_manager_id uuid default null,
  p_marital_status text default null,
  p_address text default null,
  p_city text default null,
  p_country text default null,
  p_passport_no text default null,
  p_passport_expiry date default null,
  p_residency_issue_date date default null,
  p_residency_expiry_date date default null,
  p_insurance_start_date date default null,
  p_insurance_expiry_date date default null,
  p_insurance_provider text default null,
  p_insurance_policy_no text default null,
  p_education_level text default null,
  p_major text default null,
  p_university text default null,
  p_bank_name text default null,
  p_iban text default null,
  p_account_number text default null,
  p_payment_method text default null
)
returns uuid
language plpgsql
security definer
as $$
declare
  v_employee_id uuid;
begin
  insert into public.employees(
    tenant_id,
    full_name,
    email,
    phone,
    photo_url,
    national_id,
    date_of_birth,
    gender,
    nationality,
    education,
    national_id_expiry,
    notes,
    manager_id,
    department_id,
    job_title_id,
    hire_date,
    employment_type,
    status
  )
  values (
    p_tenant_id,
    p_full_name,
    p_email,
    p_phone,
    p_photo_url,
    p_national_id,
    p_date_of_birth,
    p_gender,
    p_nationality,
    p_education,
    p_national_id_expiry,
    p_notes,
    p_manager_id,
    p_department_id,
    p_job_title_id,
    p_hire_date,
    p_employment_type,
    'active'
  )
  returning id into v_employee_id;

  insert into public.employee_compensation(
    tenant_id,
    employee_id,
    basic_salary,
    housing_allowance,
    transport_allowance,
    other_allowance
  )
  values (
    p_tenant_id,
    v_employee_id,
    p_basic_salary,
    p_housing_allowance,
    p_transport_allowance,
    p_other_allowance
  );

  insert into public.employee_personal(
    employee_id,
    tenant_id,
    nationality,
    marital_status,
    address,
    city,
    country,
    passport_no,
    passport_expiry,
    residency_issue_date,
    residency_expiry_date,
    insurance_start_date,
    insurance_expiry_date,
    insurance_provider,
    insurance_policy_no,
    education_level,
    major,
    university
  )
  values (
    v_employee_id,
    p_tenant_id,
    p_nationality,
    p_marital_status,
    p_address,
    p_city,
    p_country,
    p_passport_no,
    p_passport_expiry,
    p_residency_issue_date,
    p_residency_expiry_date,
    p_insurance_start_date,
    p_insurance_expiry_date,
    p_insurance_provider,
    p_insurance_policy_no,
    p_education_level,
    p_major,
    p_university
  );

  insert into public.employee_financial(
    employee_id,
    tenant_id,
    bank_name,
    iban,
    account_number,
    payment_method
  )
  values (
    v_employee_id,
    p_tenant_id,
    p_bank_name,
    p_iban,
    p_account_number,
    coalesce(p_payment_method, 'bank')
  );

  insert into public.employee_contracts(
    tenant_id,
    employee_id,
    contract_type,
    start_date,
    end_date,
    probation_months,
    file_url
  )
  values (
    p_tenant_id,
    v_employee_id,
    p_contract_type,
    p_contract_start,
    p_contract_end,
    p_probation_months,
    p_contract_file_url
  );

  return v_employee_id;
end;
$$;
