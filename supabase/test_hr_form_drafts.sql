-- Optional integration checks. Run AFTER install_hr_form_drafts.sql as the
-- SQL Editor postgres role. All temporary drafts and history are rolled back.
begin;
do $test$
declare
  v_actor public.users%rowtype;
  v_first public.hr_form_drafts%rowtype;
  v_saved public.hr_form_drafts%rowtype;
  v_other uuid := gen_random_uuid();
  v_wrong_tenant uuid := gen_random_uuid();
  v_private uuid := gen_random_uuid();
  v_foreign uuid := gen_random_uuid();
begin
  select * into v_actor from public.users where is_active is true
    and role in ('hr','admin') and tenant_id is not null order by id limit 1;
  if not found then raise exception 'An active HR/Admin account is required for this test'; end if;

  insert into public.hr_form_drafts(id,tenant_id,created_by,template_id)
    values(v_private,v_actor.tenant_id,v_other,'hiring-request'),
          (v_foreign,v_wrong_tenant,v_actor.id,'hiring-request');
  perform set_config('request.jwt.claim.sub',v_actor.id::text,true);
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_actor.id,'role','authenticated')::text,true);
  execute 'set local role authenticated';

  select * into v_first from public.hr_save_form_draft('hiring-request',null,
    '{"fields":{"headcount":"3"},"checks":{}}'::jsonb);
  if v_first.created_by <> v_actor.id or v_first.tenant_id <> v_actor.tenant_id
    or v_first.version <> 1 or v_first.status <> 'draft' then raise exception 'Create failed'; end if;
  select * into v_saved from public.hr_save_form_draft('hiring-request',null,
    '{"fields":{"headcount":"4"},"checks":{}}'::jsonb,v_first.id,1);
  if v_saved.version <> 2 or v_saved.data #>> '{fields,headcount}' <> '4' then raise exception 'Update failed'; end if;

  begin
    perform public.hr_save_form_draft('hiring-request',null,'{}'::jsonb,v_first.id,1);
    raise exception 'Expected stale-version failure';
  exception when serialization_failure then null;
  end;
  if (select count(*) from public.hr_form_draft_events where draft_id = v_first.id) <> 2 then
    raise exception 'History must contain only the two successful saves'; end if;
  if exists(select 1 from public.hr_form_drafts where id in (v_private,v_foreign)) then
    raise exception 'RLS exposed another owner or tenant'; end if;
  begin
    perform public.hr_save_form_draft('hiring-request',null,'{}'::jsonb,v_private,1);
    raise exception 'Expected another-owner failure';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.hr_save_form_draft('hiring-request',gen_random_uuid(),'{}'::jsonb);
    raise exception 'Expected employee scope failure';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.hr_form_drafts set data = '{}'::jsonb where id = v_first.id;
    raise exception 'Direct writes must be blocked';
  exception when insufficient_privilege then null;
  end;

  perform set_config('request.jwt.claim.sub',v_other::text,true);
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_other,'role','authenticated')::text,true);
  if exists(select 1 from public.hr_form_drafts) then raise exception 'Unauthorized session read drafts'; end if;
  begin
    perform public.hr_save_form_draft('hiring-request',null,'{}'::jsonb);
    raise exception 'Expected unauthorized-save failure';
  exception when insufficient_privilege then null;
  end;
  execute 'reset role';
  raise notice 'HR draft integration checks passed. All test rows will be rolled back.';
end;
$test$;
rollback;
