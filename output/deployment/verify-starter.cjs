'use strict';
const { spawn } = require('node:child_process');
const assert = require('node:assert/strict');
const path = require('node:path');
const child = spawn(process.execPath, [path.join(__dirname, 'dimah-api/app.js')], {
  env: { ...process.env, PORT: '31847' }, stdio: ['ignore', 'ignore', 'pipe'],
});
let errorOutput = '';
child.stderr.on('data', data => { errorOutput += data; });
(async () => {
  try {
    let response;
    for (let i = 0; i < 40; i++) {
      try { response = await fetch('http://127.0.0.1:31847/health'); break; }
      catch { await new Promise(resolve => setTimeout(resolve, 100)); }
    }
    assert.ok(response, `Server failed to start: ${errorOutput}`);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { status: 'ok', service: 'dimah-api' });
    assert.equal((await fetch('http://127.0.0.1:31847/')).status, 200);
    assert.equal((await fetch('http://127.0.0.1:31847/app.js')).status, 404);
    assert.equal((await fetch('http://127.0.0.1:31847/health', { method: 'POST' })).status, 405);
    const head = await fetch('http://127.0.0.1:31847/health', { method: 'HEAD' });
    assert.equal(head.status, 200);
    assert.equal(await head.text(), '');
    console.log('Hosting starter: health, root, file protection, methods and HEAD passed.');
  } catch (error) {
    console.error(error);
    process.exitCode = 1;
  } finally { child.kill(); }
})();
