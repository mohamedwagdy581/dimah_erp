-- Run once in Supabase SQL Editor before using the updated accounting screens.
-- Preserves existing accounts and journals. No posting or bank transfers.
begin;
create or replace function public.accounting_save_account(
  p_id uuid,p_code text,p_name text,p_type text,p_is_active boolean
) returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_tenant uuid;
  v_existing public.accounts%rowtype;
begin
  select tenant_id into v_tenant from public.users
  where id = auth.uid() and is_active is true and role in ('admin','accountant','finance_manager');
  if v_tenant is null then raise exception 'Active accounting account required' using errcode = '42501'; end if;
  if p_id is null or p_is_active is null or nullif(btrim(p_code),'') is null
    or nullif(btrim(p_name),'') is null or length(p_code)>40 or length(p_name)>200
    or p_type is null or p_type not in ('asset','liability','equity','income','expense') then
    raise exception 'Invalid account values';
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
    insert into public.accounts(id,tenant_id,code,name,type,is_active)
    values(p_id,v_tenant,btrim(p_code),btrim(p_name),p_type,p_is_active);
  else
    if v_existing.type is distinct from p_type and exists(
      select 1 from public.journal_lines l join public.journal_entries e on e.id = l.entry_id and e.tenant_id = l.tenant_id
      where l.account_id = p_id and l.tenant_id = v_tenant and e.status = 'posted') then
      raise exception 'Cannot change the type of an account used in posted entries';
    end if;
    update public.accounts set code = btrim(p_code),name = btrim(p_name),type = p_type,is_active = p_is_active
    where id = p_id and tenant_id = v_tenant;
  end if;
  return p_id;
end;
$$;

create or replace function public.accounting_save_draft(
  p_id uuid,p_date date,p_memo text,p_lines jsonb
) returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_tenant uuid;
  v_line jsonb;
  v_account uuid;
  v_debit numeric;
  v_credit numeric;
  v_total_debit numeric := 0;
  v_total_credit numeric := 0;
  v_existing public.journal_entries%rowtype;
  v_expected jsonb;
  v_stored jsonb;
begin
  select tenant_id into v_tenant from public.users
  where id = auth.uid() and is_active is true and role in ('admin','accountant','finance_manager');
  if v_tenant is null then raise exception 'Active accounting account required' using errcode = '42501'; end if;
  if p_id is null or p_date is null or length(coalesce(p_memo,''))>500
    or p_lines is null or jsonb_typeof(p_lines) is distinct from 'array' then
    raise exception 'Invalid draft values';
  end if;
  if jsonb_array_length(p_lines)<2 or jsonb_array_length(p_lines)>2000 then
    raise exception 'Draft requires 2 to 2000 lines';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_id::text,3));
  for v_line in select value from jsonb_array_elements(p_lines) loop
    if jsonb_typeof(v_line) is distinct from 'object'
      or jsonb_typeof(v_line -> 'debit') is distinct from 'number'
      or jsonb_typeof(v_line -> 'credit') is distinct from 'number' then
      raise exception 'Invalid draft line';
    end if;
    v_account := (v_line ->> 'account_id')::uuid;
    v_debit := (v_line ->> 'debit')::numeric;
    v_credit := (v_line ->> 'credit')::numeric;
    if v_account is null or v_debit is null or v_credit is null
      or v_debit::text in ('NaN','Infinity','-Infinity') or v_credit::text in ('NaN','Infinity','-Infinity')
      or v_debit < 0 or v_credit < 0 or (v_debit = 0 and v_credit = 0)
      or (v_debit > 0 and v_credit > 0) or v_debit > 999999999999.99 or v_credit > 999999999999.99
      or round(v_debit,2) <> v_debit or round(v_credit,2) <> v_credit then
      raise exception 'Line requires one positive debit or credit with at most two decimal places';
    end if;
    perform 1 from public.accounts where id = v_account and tenant_id = v_tenant and is_active is true for share;
    if not found then raise exception 'Active account outside tenant or missing' using errcode = '42501'; end if;
    v_total_debit := v_total_debit + v_debit;
    v_total_credit := v_total_credit + v_credit;
  end loop;
  if v_total_debit <> v_total_credit then raise exception 'Debits must equal credits'; end if;
  select * into v_existing from public.journal_entries where id = p_id for update;
  if found then
    select jsonb_agg(jsonb_build_array(x ->> 'account_id',(x ->> 'debit')::numeric,(x ->> 'credit')::numeric)
      order by x ->> 'account_id',(x ->> 'debit')::numeric,(x ->> 'credit')::numeric)
    into v_expected from jsonb_array_elements(p_lines) x;
    select jsonb_agg(jsonb_build_array(account_id::text,debit,credit) order by account_id::text,debit,credit)
    into v_stored from public.journal_lines where entry_id = p_id and tenant_id = v_tenant;
    if v_existing.tenant_id = v_tenant and v_existing.entry_date = p_date
      and v_existing.memo = btrim(coalesce(p_memo,'')) and v_existing.status = 'draft'
      and v_existing.total_debit = v_total_debit and v_existing.total_credit = v_total_credit
      and v_expected = v_stored then return p_id; end if;
    raise exception 'Draft request already used with different values';
  end if;
  insert into public.journal_entries(id,tenant_id,entry_date,memo,total_debit,total_credit,status)
  values(p_id,v_tenant,p_date,btrim(coalesce(p_memo,'')),v_total_debit,v_total_credit,'draft');
  insert into public.journal_lines(tenant_id,entry_id,account_id,debit,credit)
  select v_tenant,p_id,(x ->> 'account_id')::uuid,(x ->> 'debit')::numeric,(x ->> 'credit')::numeric
  from jsonb_array_elements(p_lines) x;
  return p_id;
end;
$$;
revoke all on function public.accounting_save_account(uuid,text,text,text,boolean) from public;
revoke all on function public.accounting_save_draft(uuid,date,text,jsonb) from public;
grant execute on function public.accounting_save_account(uuid,text,text,text,boolean) to authenticated;
grant execute on function public.accounting_save_draft(uuid,date,text,jsonb) to authenticated;
notify pgrst,'reload schema';
commit;
