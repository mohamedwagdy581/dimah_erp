-- Run once in Supabase SQL Editor. Preserves existing employees and accounts.
-- The complete employee, personal, bank, compensation and contract rows commit together.
begin;
create table if not exists public.hr_employee_creation_requests (
  request_id uuid primary key,
  tenant_id uuid not null references public.tenants(id),
  employee_id uuid not null references public.employees(id),
  payload_fingerprint text not null,
  created_at timestamptz not null default now()
);
alter table public.hr_employee_creation_requests enable row level security;
revoke all on public.hr_employee_creation_requests from anon, authenticated;
create or replace function public.hr_create_employee_complete(
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
  p_payment_method text default null,
  p_request_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_employee_id uuid;
  v_actor_tenant uuid;
  v_fingerprint text;
  v_request public.hr_employee_creation_requests%rowtype;
begin
  select tenant_id into v_actor_tenant from public.users
  where id = auth.uid() and is_active is true and role in ('hr', 'admin');
  if v_actor_tenant is null or v_actor_tenant is distinct from p_tenant_id then
    raise exception 'Active HR/admin in this tenant required' using errcode = '42501';
  end if;
  if p_request_id is null or nullif(btrim(p_full_name), '') is null
    or nullif(btrim(p_email), '') is null or nullif(btrim(p_phone), '') is null
    or nullif(btrim(p_national_id), '') is null or p_hire_date is null or p_contract_start is null
    or nullif(btrim(p_employment_type), '') is null or nullif(btrim(p_contract_type), '') is null then
    raise exception 'Required employee data missing';
  end if;
  if p_contract_end < p_contract_start or p_passport_expiry < p_date_of_birth
    or p_residency_expiry_date < p_residency_issue_date or p_insurance_expiry_date < p_insurance_start_date
    or p_probation_months < 0 then raise exception 'Invalid employee dates'; end if;
  if p_basic_salary is null or p_housing_allowance is null or p_transport_allowance is null or p_other_allowance is null
    or least(p_basic_salary, p_housing_allowance, p_transport_allowance, p_other_allowance) < 0
    or p_basic_salary::text in ('NaN','Infinity','-Infinity')
    or p_housing_allowance::text in ('NaN','Infinity','-Infinity')
    or p_transport_allowance::text in ('NaN','Infinity','-Infinity')
    or p_other_allowance::text in ('NaN','Infinity','-Infinity') then raise exception 'Invalid compensation'; end if;
  if not exists(select 1 from public.departments where id = p_department_id and tenant_id = v_actor_tenant)
    or not exists(select 1 from public.job_titles where id = p_job_title_id and tenant_id = v_actor_tenant)
    or (p_manager_id is not null and not exists(select 1 from public.employees where id = p_manager_id and tenant_id = v_actor_tenant))
    then raise exception 'Employee references outside tenant' using errcode = '42501'; end if;
  v_fingerprint := md5(jsonb_build_array(p_tenant_id, p_full_name, p_email, p_phone, p_national_id, p_department_id, p_job_title_id, p_hire_date, p_employment_type, p_basic_salary, p_housing_allowance, p_transport_allowance, p_other_allowance, p_contract_type, p_contract_start, p_contract_end, p_probation_months, p_contract_file_url, p_photo_url, p_date_of_birth, p_gender, p_nationality, p_education, p_national_id_expiry, p_notes, p_manager_id, p_marital_status, p_address, p_city, p_country, p_passport_no, p_passport_expiry, p_residency_issue_date, p_residency_expiry_date, p_insurance_start_date, p_insurance_expiry_date, p_insurance_provider, p_insurance_policy_no, p_education_level, p_major, p_university, p_bank_name, p_iban, p_account_number, p_payment_method)::text);
  perform pg_advisory_xact_lock(hashtextextended(p_request_id::text, 0));
  select * into v_request from public.hr_employee_creation_requests where request_id = p_request_id;
  if found then
    if v_request.tenant_id = v_actor_tenant and v_request.payload_fingerprint = v_fingerprint then
      return v_request.employee_id;
    end if;
    raise exception 'Employee creation request already used for different data';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(lower(btrim(p_email)), 1));
  if exists(select 1 from public.employees where lower(btrim(email)) = lower(btrim(p_email))) then
    raise exception 'Employee email already exists; repair the existing employee instead' using errcode = '23505';
  end if;
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

  insert into public.hr_employee_creation_requests(request_id, tenant_id, employee_id, payload_fingerprint)
  values(p_request_id, v_actor_tenant, v_employee_id, v_fingerprint);
  return v_employee_id;
end;
$$;


revoke all on function public.hr_create_employee_complete(uuid,text,text,text,text,uuid,uuid,date,text,numeric,numeric,numeric,numeric,text,date,date,int,text,text,date,text,text,text,date,text,uuid,text,text,text,text,text,date,date,date,date,date,text,text,text,text,text,text,text,text,text,uuid) from public;
grant execute on function public.hr_create_employee_complete(uuid,text,text,text,text,uuid,uuid,date,text,numeric,numeric,numeric,numeric,text,date,date,int,text,text,date,text,text,text,date,text,uuid,text,text,text,text,text,date,date,date,date,date,text,text,text,text,text,text,text,text,text,uuid) to authenticated;

-- Called only by the Edge Function after validating the HR/admin caller.
create or replace function public.hr_employee_creation_ready(p_actor_id uuid)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not exists(select 1 from public.users where id = p_actor_id and is_active is true and role in ('hr','admin')) then
    raise exception 'Active HR/admin required' using errcode = '42501';
  end if;
  if to_regprocedure('public.employee_login_context(uuid,uuid)') is null
    or to_regprocedure('public.complete_employee_login(uuid,uuid,uuid,text)') is null then
    raise exception 'Employee login provisioning SQL not installed';
  end if;
  return jsonb_build_object('ready', true, 'version', 2);
end;
$$;
revoke all on function public.hr_employee_creation_ready(uuid) from public, anon, authenticated;
grant execute on function public.hr_employee_creation_ready(uuid) to service_role;
notify pgrst, 'reload schema';
commit;

