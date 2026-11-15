'use strict';
const assert = require('node:assert/strict');
const { createApi } = require('./dimah-api/server');
(async () => {
  const server = createApi({ env: { ALLOWED_ORIGINS: 'https://erp.example.invalid' },
    fetchImpl: () => { throw Error('Preflight must not access Supabase'); } });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const url = `http://127.0.0.1:${server.address().port}/v1/me`;
  try {
    for (const origin of ['http://localhost:3000', 'http://127.0.0.1:51234', 'https://erp.example.invalid']) {
      const res = await fetch(url, { method: 'OPTIONS', headers: {
        Origin: origin, 'Access-Control-Request-Method': 'GET',
        'Access-Control-Request-Headers': 'authorization',
      } });
      assert.equal(res.status, 204);
      assert.equal(res.headers.get('Access-Control-Allow-Origin'), origin);
      assert.match(res.headers.get('Access-Control-Allow-Headers'), /Authorization/);
    }
    const denied = await fetch(url, { method: 'OPTIONS', headers: { Origin: 'https://localhost.attacker.invalid' } });
    assert.equal(denied.status, 403);
    assert.equal(denied.headers.get('Access-Control-Allow-Origin'), null);
    const unauth = await fetch(url, { headers: { Origin: 'http://localhost:3000' } });
    assert.equal(unauth.status, 401);
    assert.equal(unauth.headers.get('Access-Control-Allow-Origin'), 'http://localhost:3000');
    console.log('Browser checks passed: local/configured origins, preflight, denied origins, authentication still required.');
  } finally { await new Promise(resolve => server.close(resolve)); }
})().catch(error => { console.error(error); process.exitCode = 1; });
