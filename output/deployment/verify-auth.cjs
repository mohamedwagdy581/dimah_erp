'use strict';
const assert = require('node:assert/strict');
const { createApi, configuration } = require('./dimah-api/server');
const uid = '11111111-1111-4111-8111-111111111111';
const account = { id: uid, email: 'test@example.invalid', role: 'employee', tenant_id: 'tenant-a', employee_id: 'employee-a', is_active: true };
const env = { SUPABASE_URL: 'https://example.supabase.co', SUPABASE_ANON_KEY: 'sb_publishable_test' };
const token = { Authorization: 'Bearer test-token' };
const response = (data, status = 200) => new Response(JSON.stringify(data), { status });
async function runCase(options, headers, expected, check) {
  const server = createApi(options);
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  try {
    const result = await fetch(`http://127.0.0.1:${server.address().port}/v1/me?tenant_id=attacker&id=other`, { headers });
    assert.equal(result.status, expected);
    const data = await result.json();
    if (check) check(data);
  } finally { await new Promise(resolve => server.close(resolve)); }
}
(async () => {
  assert.equal(configuration({ ...env, SUPABASE_ANON_KEY: 'sb_secret_privileged' }), null);
  const serviceKey = `header.${Buffer.from(JSON.stringify({ role: 'service_role' })).toString('base64url')}.signature`;
  assert.equal(configuration({ ...env, SUPABASE_ANON_KEY: serviceKey }), null);
  await runCase({ env, fetchImpl: () => { throw Error('Must not query without auth'); } }, {}, 401);
  await runCase({ env: {} }, token, 503);
  let calls = 0;
  await runCase({ env, fetchImpl: async () => { calls++; return response({}, 401); } }, token, 401);
  assert.equal(calls, 1);
  const fetchFor = rows => async (url, options) => {
    assert.equal(options.headers.Authorization, token.Authorization);
    assert.equal(options.headers.apikey, env.SUPABASE_ANON_KEY);
    if (url.endsWith('/auth/v1/user')) return response({ id: uid });
    const parsed = new URL(url);
    assert.equal(parsed.searchParams.get('id'), `eq.${uid}`);
    assert.equal(parsed.searchParams.has('tenant_id'), false);
    assert.equal(parsed.searchParams.get('limit'), '1');
    return response(rows);
  };
  await runCase({ env, fetchImpl: fetchFor([{ ...account, private_field: 'hidden' }]) }, token, 200,
    data => assert.deepEqual(data, { user: account }));
  await runCase({ env, fetchImpl: fetchFor([{ ...account, is_active: false }]) }, token, 403);
  await runCase({ env, fetchImpl: fetchFor([]) }, token, 403);
  await runCase({ env, fetchImpl: fetchFor([{ ...account, id: 'another-user' }]) }, token, 403);
  await runCase({ env, fetchImpl: async () => response({ password: 'sensitive upstream error' }, 500) }, token, 502,
    data => assert.deepEqual(data, { error: 'identity_service_unavailable' }));
  await runCase({ env, fetchImpl: async () => { throw Error('secret'); } }, token, 502,
    data => assert.deepEqual(data, { error: 'upstream_unavailable' }));
  console.log('Auth checks passed: identity validation, user scoping, inactive/missing accounts, privileged key rejection, safe failures.');
})().catch(error => { console.error(error); process.exitCode = 1; });
