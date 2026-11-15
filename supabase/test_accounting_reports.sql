-- Optional integration checks. Run AFTER install_accounting_reports.sql as the
-- SQL Editor postgres role. Uses an existing active accountant/finance_manager/admin
-- user; all test accounts and entries (dated 2001) are rolled back at the end.
-- Success = the script ends with "ROLLBACK" and no error.
begin;
do $test$
declare
  v_actor public.users%rowtype;
  v_t uuid;
  v_bank uuid := gen_random_uuid();
  v_pay uuid := gen_random_uuid();
  v_sales uuid := gen_random_uuid();
  v_sal uuid := gen_random_uuid();
  v_old uuid := gen_random_uuid();
  v_e1 uuid := gen_random_uuid();
  v_e2 uuid := gen_random_uuid();
  v_d1 uuid := gen_random_uuid();
  v_bad uuid := gen_random_uuid();
  v_one uuid := gen_random_uuid();
  v_inact uuid := gen_random_uuid();
  v_oldpost uuid := gen_random_uuid();
  v_foreign_tenant uuid;
  v_foreign_acc uuid := gen_random_uuid();
  v_posted_at timestamptz;
  v_j jsonb;
  v_k jsonb;
  v_dr numeric;
  v_cr numeric;
begin
  select * into v_actor from public.users where is_active is true
    and role in ('accountant','finance_manager','admin') and tenant_id is not null order by id limit 1;
  if not found then raise exception 'An active accountant/finance_manager/admin account is required'; end if;
  v_t := v_actor.tenant_id;

  -- Seed (as postgres) ---------------------------------------------------
  insert into public.accounts(id,tenant_id,code,name,type,is_active,is_cash) values
    (v_bank,v_t,'ZT-1100','Test Bank','asset',true,true),
    (v_pay,v_t,'ZT-2100','Test Payables','liability',true,false),
    (v_sales,v_t,'ZT-4100','Test Sales','income',true,false),
    (v_sal,v_t,'ZT-5100','Test Salaries','expense',true,false),
    (v_old,v_t,'ZT-5900','Test Old','expense',true,false);
  insert into public.journal_entries(id,tenant_id,entry_date,memo,total_debit,total_credit,status,created_at) values
    (v_e1,v_t,'2001-10-05','E1 sale',1000,1000,'draft',now()),
    (v_e2,v_t,'2001-10-20','E2 salaries',400,400,'draft',now()),
    (v_d1,v_t,'2001-10-25','D1 draft only',50,50,'draft',now() - interval '10 days'),
    (v_bad,v_t,'2001-10-26','unbalanced',100,90,'draft',now()),
    (v_one,v_t,'2001-10-27','one line',10,10,'draft',now()),
    (v_inact,v_t,'2001-10-28','uses old',5,5,'draft',now()),
    (v_oldpost,v_t,'2001-09-15','old history',70,70,'posted',now());
  insert into public.journal_lines(tenant_id,entry_id,account_id,debit,credit) values
    (v_t,v_e1,v_bank,1000,0),(v_t,v_e1,v_sales,0,1000),
    (v_t,v_e2,v_sal,400,0),(v_t,v_e2,v_bank,0,400),
    (v_t,v_d1,v_sal,50,0),(v_t,v_d1,v_bank,0,50),
    (v_t,v_bad,v_sal,100,0),(v_t,v_bad,v_bank,0,90),
    (v_t,v_one,v_sal,10,0),
    (v_t,v_inact,v_old,5,0),(v_t,v_inact,v_bank,0,5),
    (v_t,v_oldpost,v_old,70,0),(v_t,v_oldpost,v_pay,0,70);
  update public.accounts set is_active = false where id = v_old;

  -- Act as the accounting user --------------------------------------------
  perform set_config('request.jwt.claim.sub',v_actor.id::text,true);
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_actor.id,'role','authenticated')::text,true);
  execute 'set local role authenticated';

  begin
    perform public.accounting_post_entry(v_bad);
    raise exception 'Expected unbalanced failure';
  exception when others then
    if sqlerrm not like '%Debits must equal credits%' then raise; end if;
  end;
  begin
    perform public.accounting_post_entry(v_one);
    raise exception 'Expected single-line failure';
  exception when others then
    if sqlerrm not like '%at least 2 lines%' then raise; end if;
  end;
  begin
    perform public.accounting_post_entry(v_inact);
    raise exception 'Expected inactive-account failure';
  exception when others then
    if sqlerrm not like '%inactive account%' then raise; end if;
  end;

  perform public.accounting_post_entry(v_e1);
  execute 'reset role';
  select posted_at into v_posted_at from public.journal_entries
    where id = v_e1 and status = 'posted' and posted_by = v_actor.id;
  if v_posted_at is null then raise exception 'E1 not posted with posted_at/posted_by'; end if;
  execute 'set local role authenticated';
  -- Retry must be a no-op. now() is fixed inside a transaction, so plant a
  -- sentinel first: a non-idempotent re-post would overwrite it.
  execute 'reset role';
  update public.journal_entries set posted_at = '2000-01-01', posted_by = null where id = v_e1;
  execute 'set local role authenticated';
  perform public.accounting_post_entry(v_e1);
  execute 'reset role';
  if (select posted_at from public.journal_entries where id = v_e1) is distinct from '2000-01-01'::timestamptz
    or (select posted_by from public.journal_entries where id = v_e1) is not null then
    raise exception 'Re-posting must not change posted_at/posted_by'; end if;
  execute 'set local role authenticated';

  begin
    perform public.accounting_save_draft(v_e1,'2001-10-05','changed',
      jsonb_build_array(jsonb_build_object('account_id',v_bank,'debit',1,'credit',0),
                        jsonb_build_object('account_id',v_sales,'debit',0,'credit',1)));
    raise exception 'Expected posted entry to be immutable';
  exception when others then
    if sqlerrm not like '%already used with different values%' then raise; end if;
  end;

  perform public.accounting_post_entry(v_e2);

  -- Ledger ---------------------------------------------------------------
  v_j := public.accounting_ledger(v_bank,'2001-10-10','2001-10-31');
  if v_j is null or (v_j->>'opening')::numeric <> 1000 or (v_j->>'closing')::numeric <> 600
    or (v_j->>'total_credit')::numeric <> 400 or jsonb_array_length(v_j->'rows') <> 1
    or (v_j->'rows'->0->>'balance')::numeric <> 600 or (v_j->>'truncated')::boolean then
    raise exception 'Bank ledger wrong: %',v_j; end if;
  v_j := public.accounting_ledger(v_sales,'2001-10-01','2001-10-31');
  if (v_j->'rows'->0->>'balance')::numeric <> 1000 or (v_j->>'closing')::numeric <> 1000 then
    raise exception 'Sales ledger must be credit-normal positive: %',v_j; end if;
  v_j := public.accounting_ledger(v_pay,'2001-10-01','2001-10-31');
  if jsonb_array_length(v_j->'rows') <> 0 or (v_j->>'opening')::numeric <> 70
    or (v_j->>'closing')::numeric <> 70 then raise exception 'Payables ledger (no movements, credit opening 70) wrong: %',v_j; end if;
  begin
    perform public.accounting_ledger(v_bank,'2001-11-01','2001-10-01');
    raise exception 'Expected invalid range';
  exception when others then
    if sqlerrm not like '%Invalid date range%' then raise; end if;
  end;

  -- Trial balance ----------------------------------------------------------
  select sum(debit),sum(credit) into v_dr,v_cr from public.accounting_trial_balance('2001-10-31');
  if v_dr is distinct from v_cr then raise exception 'Trial balance not balanced: % vs %',v_dr,v_cr; end if;
  if (select debit from public.accounting_trial_balance('2001-10-31') where account_id = v_bank) is distinct from 600::numeric
    or (select credit from public.accounting_trial_balance('2001-10-31') where account_id = v_sales) is distinct from 1000::numeric
    or (select debit from public.accounting_trial_balance('2001-10-31') where account_id = v_sal) is distinct from 400::numeric
    or (select debit from public.accounting_trial_balance('2001-10-31') where account_id = v_old) is distinct from 70::numeric then
    raise exception 'Trial balance rows wrong (inactive account with history must stay listed)'; end if;
  if exists(select 1 from public.accounting_trial_balance('2001-10-04') where account_id = v_bank) then
    raise exception 'Trial balance must ignore entries after as-of date'; end if;

  -- KPIs -------------------------------------------------------------------
  v_k := public.accounting_kpis('2001-10-15');
  if v_k is null or (v_k->>'revenue')::numeric <> 1000 or (v_k->>'expenses')::numeric <> 400
    or (v_k->>'net_profit')::numeric <> 600 or (v_k->>'cash_balance')::numeric < 600
    or not (v_k->>'has_cash_accounts')::boolean
    or (v_k->>'draft_count')::int < 4 or (v_k->>'stale_draft_count')::int < 1 then
    raise exception 'KPIs wrong: %',v_k; end if;

  -- Cash flag rule ---------------------------------------------------------
  begin
    perform public.accounting_save_account(gen_random_uuid(),'ZT-5999','Bad cash','expense',true,true);
    raise exception 'Expected cash-only-assets failure';
  exception when others then
    if sqlerrm not like '%Only asset accounts can be cash%' then raise; end if;
  end;

  -- Foreign tenant account -------------------------------------------------
  execute 'reset role';
  select id into v_foreign_tenant from public.tenants where id <> v_t limit 1;
  if v_foreign_tenant is not null then
    insert into public.accounts(id,tenant_id,code,name,type) values
      (v_foreign_acc,v_foreign_tenant,'ZT-F1','Foreign','asset');
    insert into public.journal_entries(id,tenant_id,entry_date,memo,total_debit,total_credit,status)
      values(v_foreign_acc,v_foreign_tenant,'2001-10-01','foreign',0,0,'draft');
    execute 'set local role authenticated';
    begin
      perform public.accounting_post_entry(v_foreign_acc);
      raise exception 'Expected foreign entry failure';
    exception when insufficient_privilege then null;
    end;
    if exists(select 1 from public.accounting_trial_balance('2001-12-31') where account_id = v_foreign_acc) then
      raise exception 'Trial balance leaked a foreign tenant account'; end if;
    begin
      perform public.accounting_ledger(v_foreign_acc,'2001-01-01','2001-12-31');
      raise exception 'Expected foreign tenant failure';
    exception when insufficient_privilege then null;
    end;
    execute 'reset role';
  else
    raise notice 'Skipped foreign-tenant check: only one tenant exists';
  end if;

  -- Unauthorised session ---------------------------------------------------
  perform set_config('request.jwt.claim.sub',gen_random_uuid()::text,true);
  perform set_config('request.jwt.claims',jsonb_build_object('sub',gen_random_uuid(),'role','authenticated')::text,true);
  execute 'set local role authenticated';
  begin perform public.accounting_kpis('2001-10-15'); raise exception 'Expected 42501 kpis';
  exception when insufficient_privilege then null; end;
  begin perform public.accounting_trial_balance('2001-10-31'); raise exception 'Expected 42501 tb';
  exception when insufficient_privilege then null; end;
  begin perform public.accounting_ledger(v_bank,'2001-10-01','2001-10-31'); raise exception 'Expected 42501 ledger';
  exception when insufficient_privilege then null; end;
  begin perform public.accounting_post_entry(v_d1); raise exception 'Expected 42501 post';
  exception when insufficient_privilege then null; end;
  execute 'reset role';

  raise notice 'All accounting report checks passed';
end;
$test$;
rollback;
