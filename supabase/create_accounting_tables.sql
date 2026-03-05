create table if not exists public.accounts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  code text not null,
  name text not null,
  type text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  entry_date date not null,
  memo text not null,
  total_debit numeric not null default 0,
  total_credit numeric not null default 0,
  status text not null default 'draft',
  created_at timestamptz not null default now()
);

create table if not exists public.journal_lines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  entry_id uuid not null references public.journal_entries(id),
  account_id uuid not null references public.accounts(id),
  debit numeric not null default 0,
  credit numeric not null default 0
);

create index if not exists idx_accounts_tenant_code
  on public.accounts (tenant_id, code);

create index if not exists idx_journal_entries_tenant_date
  on public.journal_entries (tenant_id, entry_date);

create index if not exists idx_journal_lines_entry
  on public.journal_lines (entry_id);
