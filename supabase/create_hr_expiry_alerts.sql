alter table public.employee_personal
  add column if not exists residency_issue_date date null,
  add column if not exists residency_expiry_date date null,
  add column if not exists insurance_start_date date null,
  add column if not exists insurance_expiry_date date null,
  add column if not exists insurance_provider text null,
  add column if not exists insurance_policy_no text null;

create table if not exists public.expiry_alert_settings (
  tenant_id uuid primary key references public.tenants(id),
  contract_alert_days int not null default 90,
  residency_alert_days int not null default 90,
  insurance_alert_days int not null default 90,
  documents_alert_days int not null default 90,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (contract_alert_days > 0 and contract_alert_days <= 365),
  check (residency_alert_days > 0 and residency_alert_days <= 365),
  check (insurance_alert_days > 0 and insurance_alert_days <= 365),
  check (documents_alert_days > 0 and documents_alert_days <= 365)
);

alter table public.expiry_alert_settings
  add column if not exists documents_alert_days int not null default 90;

insert into public.expiry_alert_settings (
  tenant_id,
  contract_alert_days,
  residency_alert_days,
  insurance_alert_days,
  documents_alert_days
)
select t.id, 90, 90, 90, 90
from public.tenants t
where not exists (
  select 1
  from public.expiry_alert_settings s
  where s.tenant_id = t.id
);

create or replace function public.touch_expiry_alert_settings_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_expiry_alert_settings_updated_at
  on public.expiry_alert_settings;

create trigger trg_expiry_alert_settings_updated_at
before update on public.expiry_alert_settings
for each row
execute function public.touch_expiry_alert_settings_updated_at();

create or replace function public.upsert_expiry_alert_settings(
  p_tenant_id uuid,
  p_contract_alert_days int,
  p_residency_alert_days int,
  p_insurance_alert_days int,
  p_documents_alert_days int
)
returns void
language plpgsql
security definer
as $$
begin
  insert into public.expiry_alert_settings (
    tenant_id,
    contract_alert_days,
    residency_alert_days,
    insurance_alert_days,
    documents_alert_days
  )
  values (
    p_tenant_id,
    p_contract_alert_days,
    p_residency_alert_days,
    p_insurance_alert_days,
    p_documents_alert_days
  )
  on conflict (tenant_id)
  do update
  set contract_alert_days = excluded.contract_alert_days,
      residency_alert_days = excluded.residency_alert_days,
      insurance_alert_days = excluded.insurance_alert_days,
      documents_alert_days = excluded.documents_alert_days,
      updated_at = now();
end;
$$;
