-- Accounting reports (Stage 1): posting, general ledger, trial balance, KPIs.
-- Run once in the Supabase SQL Editor AFTER install_accounting_workspace.sql.
-- Safe to re-run. Preserves all existing accounts and journal entries.
-- Then run test_accounting_reports.sql to verify (it rolls everything back).
begin;

-- 1. Schema --------------------------------------------------------------
alter table public.accounts add column if not exists is_cash boolean not null default false;
alter table public.journal_entries add column if not exists posted_at timestamptz;
alter table public.journal_entries add column if not exists posted_by uuid references public.users(id);
create index if not exists idx_journal_lines_tenant_account
  on public.journal_lines (tenant_id, account_id);
create index if not exists idx_journal_entries_tenant_status_date
  on public.journal_entries (tenant_id, status, entry_date);

-- Shared guard: active accounting user of a tenant, else 42501.
create or replace function public.accounting_actor_tenant()
returns uuid language plpgsql stable security definer set search_path = public, pg_temp as $$
declare v_tenant uuid;
begin
  select tenant_id into v_tenant from public.users
  where id = auth.uid() and is_active is true and role in ('admin','accountant','finance_manager');
  if v_tenant is null then
    raise exception 'Active accounting account required' using errcode = '42501';
  end if;
  return v_tenant;
end;
$$;

-- 2. Save account (adds is_cash) -----------------------------------------
drop function if exists public.accounting_save_account(uuid,text,text,text,boolean);
create or replace function public.accounting_save_account(
  p_id uuid,p_code text,p_name text,p_type text,p_is_active boolean,p_is_cash boolean default false
) returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_tenant uuid := public.accounting_actor_tenant();
  v_existing public.accounts%rowtype;
  v_is_cash boolean := coalesce(p_is_cash,false);
begin
  if p_id is null or p_is_active is null or nullif(btrim(p_code),'') is null
    or nullif(btrim(p_name),'') is null or length(p_code)>40 or length(p_name)>200
    or p_type is null or p_type not in ('asset','liability','equity','income','expense') then
    raise exception 'Invalid account values';
  end if;
  if v_is_cash and p_type <> 'asset' then
    raise exception 'Only asset accounts can be cash';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(v_tenant::text,2));
  select * into v_existing from public.accounts where id = p_id for update;
  if found and v_existing.tenant_id is distinct from v_tenant then
    raise exception 'Account outside tenant' using errcode = '42501';
  end if;
  if exists(select 1 from public.accounts where tenant_id = v_tenant
    and lower(btrim(code)) = lower(btrim(p_code)) and id <> p_id) then
    raise exception 'Account code already in use' using errcode = '23505';
  end if;
  if v_existing.id is null then
    insert into public.accounts(id,tenant_id,code,name,type,is_active,is_cash)
    values(p_id,v_tenant,btrim(p_code),btrim(p_name),p_type,p_is_active,v_is_cash);
  else
    if v_existing.type is distinct from p_type and exists(
      select 1 from public.journal_lines l join public.journal_entries e on e.id = l.entry_id and e.tenant_id = l.tenant_id
      where l.account_id = p_id and l.tenant_id = v_tenant and e.status = 'posted') then
      raise exception 'Cannot change the type of an account used in posted entries';
    end if;
    update public.accounts set code = btrim(p_code),name = btrim(p_name),type = p_type,
      is_active = p_is_active,is_cash = v_is_cash
    where id = p_id and tenant_id = v_tenant;
  end if;
  return p_id;
end;
$$;

-- 3. Post a draft entry --------------------------------------------------
create or replace function public.accounting_post_entry(p_id uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_tenant uuid := public.accounting_actor_tenant();
  v_entry public.journal_entries%rowtype;
  v_lines int;
  v_debit numeric;
  v_credit numeric;
begin
  if p_id is null then raise exception 'Invalid entry'; end if;
  select * into v_entry from public.journal_entries where id = p_id for update;
  if not found then raise exception 'Entry not found'; end if;
  if v_entry.tenant_id is distinct from v_tenant then
    raise exception 'Entry outside tenant' using errcode = '42501';
  end if;
  if v_entry.status = 'posted' then return; end if; -- retry-safe
  if v_entry.status <> 'draft' then raise exception 'Only drafts can be posted'; end if;
  select count(*),coalesce(sum(debit),0),coalesce(sum(credit),0)
    into v_lines,v_debit,v_credit
  from public.journal_lines where entry_id = p_id and tenant_id = v_tenant;
  if v_lines < 2 then raise exception 'Entry requires at least 2 lines'; end if;
  if v_debit <> v_credit or v_debit <> v_entry.total_debit or v_credit <> v_entry.total_credit then
    raise exception 'Debits must equal credits';
  end if;
  if exists(select 1 from public.journal_lines l join public.accounts a on a.id = l.account_id
    where l.entry_id = p_id and (a.is_active is not true or a.tenant_id <> v_tenant)) then
    raise exception 'Entry uses an inactive account';
  end if;
  update public.journal_entries set status = 'posted',posted_at = now(),posted_by = auth.uid()
  where id = p_id;
end;
$$;

-- 4. General ledger for one account --------------------------------------
create or replace function public.accounting_ledger(p_account_id uuid,p_from date,p_to date)
returns jsonb language plpgsql stable security definer set search_path = public, pg_temp as $$
declare
  v_tenant uuid := public.accounting_actor_tenant();
  v_account public.accounts%rowtype;
  v_sign int;
  v_opening numeric;
  v_debit numeric;
  v_credit numeric;
  v_count int;
  v_rows jsonb;
begin
  select * into v_account from public.accounts where id = p_account_id;
  if not found or v_account.tenant_id is distinct from v_tenant then
    raise exception 'Account outside tenant or missing' using errcode = '42501';
  end if;
  if p_from is null or p_to is null or p_from > p_to then raise exception 'Invalid date range'; end if;
  v_sign := case when v_account.type in ('asset','expense') then 1 else -1 end;

  select coalesce(sum(l.debit - l.credit),0) * v_sign into v_opening
  from public.journal_lines l join public.journal_entries e on e.id = l.entry_id
  where l.tenant_id = v_tenant and l.account_id = p_account_id
    and e.status = 'posted' and e.entry_date < p_from;

  select count(*),coalesce(sum(l.debit),0),coalesce(sum(l.credit),0)
    into v_count,v_debit,v_credit
  from public.journal_lines l join public.journal_entries e on e.id = l.entry_id
  where l.tenant_id = v_tenant and l.account_id = p_account_id
    and e.status = 'posted' and e.entry_date between p_from and p_to;

  select coalesce(jsonb_agg(jsonb_build_object(
      'entry_id',r.entry_id,'entry_date',r.entry_date,'memo',r.memo,
      'debit',r.debit,'credit',r.credit,'balance',r.balance) order by r.n),'[]'::jsonb)
  into v_rows
  from (
    select x.*, row_number() over (order by x.entry_date,x.created_at,x.entry_id,x.line_id) n
    from (
      select e.id entry_id,e.entry_date,e.memo,e.created_at,l.id line_id,l.debit,l.credit,
        v_opening + sum(v_sign * (l.debit - l.credit)) over (
          order by e.entry_date,e.created_at,e.id,l.id rows unbounded preceding) balance
      from public.journal_lines l join public.journal_entries e on e.id = l.entry_id
      where l.tenant_id = v_tenant and l.account_id = p_account_id
        and e.status = 'posted' and e.entry_date between p_from and p_to
    ) x
  ) r where r.n <= 2000;

  return jsonb_build_object(
    'account',jsonb_build_object('id',v_account.id,'code',v_account.code,'name',v_account.name,'type',v_account.type),
    'opening',v_opening,'total_debit',v_debit,'total_credit',v_credit,
    'closing',v_opening + v_sign * (v_debit - v_credit),
    'truncated',v_count > 2000,'rows',v_rows);
end;
$$;

-- 5. Trial balance on a date ---------------------------------------------
create or replace function public.accounting_trial_balance(p_as_of date)
returns table(account_id uuid,code text,name text,type text,debit numeric,credit numeric)
language plpgsql stable security definer set search_path = public, pg_temp as $$
declare v_tenant uuid := public.accounting_actor_tenant();
begin
  if p_as_of is null then raise exception 'Invalid date'; end if;
  return query
  select a.id,a.code,a.name,a.type,
    greatest(sum(l.debit) - sum(l.credit),0)::numeric,
    greatest(sum(l.credit) - sum(l.debit),0)::numeric
  from public.journal_lines l
  join public.journal_entries e on e.id = l.entry_id
  join public.accounts a on a.id = l.account_id
  where l.tenant_id = v_tenant and e.status = 'posted' and e.entry_date <= p_as_of
  group by a.id,a.code,a.name,a.type
  order by a.code;
end;
$$;

-- 6. Finance Home KPIs ---------------------------------------------------
create or replace function public.accounting_kpis(p_month date)
returns jsonb language plpgsql stable security definer set search_path = public, pg_temp as $$
declare
  v_tenant uuid := public.accounting_actor_tenant();
  v_start date := date_trunc('month',coalesce(p_month,current_date))::date;
  v_end date := (date_trunc('month',coalesce(p_month,current_date)) + interval '1 month')::date;
  v_cash numeric;
  v_has_cash boolean;
  v_revenue numeric;
  v_expenses numeric;
  v_drafts int;
  v_stale int;
begin
  select exists(select 1 from public.accounts where tenant_id = v_tenant and is_cash and type = 'asset')
    into v_has_cash;
  select coalesce(sum(l.debit - l.credit),0) into v_cash
  from public.journal_lines l
  join public.journal_entries e on e.id = l.entry_id
  join public.accounts a on a.id = l.account_id
  where l.tenant_id = v_tenant and e.status = 'posted' and e.entry_date <= current_date
    and a.is_cash and a.type = 'asset';
  select coalesce(sum(case when a.type = 'income' then l.credit - l.debit else 0 end),0),
         coalesce(sum(case when a.type = 'expense' then l.debit - l.credit else 0 end),0)
    into v_revenue,v_expenses
  from public.journal_lines l
  join public.journal_entries e on e.id = l.entry_id
  join public.accounts a on a.id = l.account_id
  where l.tenant_id = v_tenant and e.status = 'posted'
    and e.entry_date >= v_start and e.entry_date < v_end;
  select count(*),count(*) filter (where created_at < now() - interval '7 days')
    into v_drafts,v_stale
  from public.journal_entries where tenant_id = v_tenant and status = 'draft';
  return jsonb_build_object('cash_balance',v_cash,'has_cash_accounts',v_has_cash,
    'revenue',v_revenue,'expenses',v_expenses,'net_profit',v_revenue - v_expenses,
    'draft_count',v_drafts,'stale_draft_count',v_stale);
end;
$$;

-- 7. Permissions ---------------------------------------------------------
revoke all on function public.accounting_actor_tenant() from public;
revoke all on function public.accounting_save_account(uuid,text,text,text,boolean,boolean) from public;
revoke all on function public.accounting_post_entry(uuid) from public;
revoke all on function public.accounting_ledger(uuid,date,date) from public;
revoke all on function public.accounting_trial_balance(date) from public;
revoke all on function public.accounting_kpis(date) from public;
grant execute on function public.accounting_save_account(uuid,text,text,text,boolean,boolean) to authenticated;
grant execute on function public.accounting_post_entry(uuid) to authenticated;
grant execute on function public.accounting_ledger(uuid,date,date) to authenticated;
grant execute on function public.accounting_trial_balance(date) to authenticated;
grant execute on function public.accounting_kpis(date) to authenticated;
notify pgrst,'reload schema';
commit;
