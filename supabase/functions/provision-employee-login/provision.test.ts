import test from 'node:test';
import assert from 'node:assert/strict';
import { provisionEmployeeLogin, ProvisionError, loginContextError, type LoginContext, type ProvisionPorts } from './provision.ts';

test('Context errors distinguish duplicate, orphan/conflicting account, tenant and missing setup', () => {
  const cases = [
    ['42501', 'Inactive employee cannot provision login', 'inactive_employee'],
    ['23505', 'Duplicate employee email; resolve duplicate records', 'duplicate_employee_email'],
    ['23505', 'Multiple Auth accounts match the email', 'duplicate_auth_email'],
    ['42501', 'Account is already assigned to another employee, company or privileged role', 'existing_account_conflict'],
    ['23505', 'Conflicting application accounts', 'duplicate_app_account'],
    ['42501', 'Employee is outside your company or does not exist', 'employee_scope'],
    ['42501', 'Only active HR and admin accounts may provision logins', 'actor_forbidden'],
    ['PGRST202', 'Function not found', 'login_setup_required'],
    ['42703', 'Column missing', 'login_setup_required'],
  ];
  for (const [code, message, expected] of cases) assert.equal(loginContextError({ code, message }).code, expected);
});

test('Unknown context errors do not expose raw database details or claim email duplication', () => {
  const result = loginContextError({ code: 'XX000', message: 'Private database details' });
  assert.equal(result.code, 'login_context_failed');
  assert.equal(result.message.includes('Private database details'), false);
  assert.equal(result.message.includes('تكرار'), false);
});

const employeeId = '10000000-0000-4000-8000-000000000001';
const authId = '20000000-0000-4000-8000-000000000001';
const ctx: LoginContext = { employeeId, tenantId: 'company', email: 'employee@example.test', name: 'Test employee', authUserId: null };
const input = { employeeId, role: 'employee' as const, initialPassword: 'Only-test@2042' };

test('New account creates Auth once, links it, and returns no password', async () => {
  const calls: string[] = [];
  const result = await provisionEmployeeLogin(input, {
    context: async () => ctx,
    createAuth: async (data, password) => { assert.equal(data.email, ctx.email); assert.equal(password, input.initialPassword); calls.push('create'); return authId; },
    complete: async (id, auth, role) => { assert.equal(id, employeeId); assert.equal(auth, authId); assert.equal(role, 'employee'); calls.push('link'); },
  });
  assert.deepEqual(calls, ['create', 'link']);
  assert.equal(result.accountCreated, true);
  assert.equal('initialPassword' in result, false);
});

test('Existing Auth account keeps its password and can be linked as manager', async () => {
  let created = false;
  const result = await provisionEmployeeLogin({ employeeId, role: 'manager' }, {
    context: async () => ({ ...ctx, authUserId: authId }),
    createAuth: async () => { created = true; return authId; },
    complete: async (_id, _auth, role) => assert.equal(role, 'manager'),
  });
  assert.equal(created, false);
  assert.equal(result.accountCreated, false);
});

test('Retry after linking failure uses the same Auth account', async () => {
  let storedAuth: string | null = null;
  let creations = 0;
  let links = 0;
  const ports: ProvisionPorts = {
    context: async () => ({ ...ctx, authUserId: storedAuth }),
    createAuth: async () => { creations++; storedAuth = authId; return authId; },
    complete: async () => { links++; if (links === 1) throw new ProvisionError(409, 'link_failed', 'Retry'); },
  };
  await assert.rejects(provisionEmployeeLogin(input, ports));
  await provisionEmployeeLogin(input, ports);
  assert.equal(creations, 1);
  assert.equal(links, 2);
});

test('Concurrent creation rechecks Auth without resetting any password', async () => {
  let reads = 0;
  const result = await provisionEmployeeLogin(input, {
    context: async () => ({ ...ctx, authUserId: ++reads > 1 ? authId : null }),
    createAuth: async () => null,
    complete: async (_id, auth) => assert.equal(auth, authId),
  });
  assert.equal(result.accountCreated, false);
  assert.equal(reads, 2);
});

test('Unsupported privilege is rejected before reading data', async () => {
  let read = false;
  await assert.rejects(provisionEmployeeLogin({ ...input, role: 'admin' as never }, {
    context: async () => { read = true; return ctx; }, createAuth: async () => authId, complete: async () => {},
  }), (error: unknown) => error instanceof ProvisionError && error.code === 'invalid_role');
  assert.equal(read, false);
});

test('Cross-company or unauthorized context never creates Auth', async () => {
  let create = false;
  await assert.rejects(provisionEmployeeLogin(input, {
    context: async () => { throw new ProvisionError(403, 'forbidden', 'Forbidden'); },
    createAuth: async () => { create = true; return authId; }, complete: async () => {},
  }));
  assert.equal(create, false);
});

test('Weak password prevents creation of a new account', async () => {
  let create = false;
  await assert.rejects(provisionEmployeeLogin({ ...input, initialPassword: 'weak' }, {
    context: async () => ctx, createAuth: async () => { create = true; return authId; }, complete: async () => {},
  }), (error: unknown) => error instanceof ProvisionError && error.code === 'weak_password');
  assert.equal(create, false);
});

test('Invalid employee ID is rejected before reading data', async () => {
  let read = false;
  await assert.rejects(provisionEmployeeLogin({ ...input, employeeId: 'bad-id' }, {
    context: async () => { read = true; return ctx; }, createAuth: async () => authId, complete: async () => {},
  }));
  assert.equal(read, false);
});
