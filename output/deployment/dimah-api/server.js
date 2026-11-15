'use strict';
const http = require('node:http');

function configuration(env) {
  try {
    const url = new URL(env.SUPABASE_URL);
    const key = (env.SUPABASE_ANON_KEY || '').trim();
    if (url.protocol !== 'https:' || url.username || url.password || url.search || url.hash ||
        url.pathname !== '/' || !key) return null;
    // Keep all database queries scoped to the caller; privileged keys are unnecessary.
    if (!key.startsWith('sb_publishable_')) {
      const claims = JSON.parse(Buffer.from(key.split('.')[1], 'base64url').toString());
      if (claims.role !== 'anon') return null;
    }
    return { url: url.origin, key };
  } catch { return null; }
}

function createApi({ env = process.env, fetchImpl = fetch } = {}) {
  const config = configuration(env);
  return http.createServer(async (req, res) => {
    const origin = req.headers.origin;
    if (origin) {
      let local = false;
      try {
        const parsed = new URL(origin);
        local = ['http:', 'https:'].includes(parsed.protocol) &&
          ['localhost', '127.0.0.1', '[::1]'].includes(parsed.hostname) &&
          parsed.origin === origin;
      } catch { /* Deny malformed browser origins. */ }
      const allowed = (env.ALLOWED_ORIGINS || '').split(',').map(value => value.trim());
      res.setHeader('Vary', 'Origin');
      if (local || allowed.includes(origin)) {
        res.setHeader('Access-Control-Allow-Origin', origin);
        res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
      } else {
        res.writeHead(403, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
        return res.end(JSON.stringify({ error: 'origin_not_allowed' }));
      }
    }
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    const reply = (status, body) => {
      res.statusCode = status;
      res.end(req.method === 'HEAD' ? undefined : JSON.stringify(body));
    };
    const path = (req.url || '/').split('?')[0];
    if (!['/', '/health', '/v1/me'].includes(path)) return reply(404, { error: 'not_found' });
    if (req.method === 'OPTIONS') { res.statusCode = 204; return res.end(); }
    if (!['GET', 'HEAD'].includes(req.method)) {
      res.setHeader('Allow', 'GET, HEAD');
      return reply(405, { error: 'method_not_allowed' });
    }
    if (path === '/health') return reply(200, { status: 'ok', service: 'dimah-api' });
    if (path === '/') return reply(200, {
      service: 'DIMAH ERP API', status: 'running', stage: 'authenticated-profile', health: '/health',
    });
    const authorization = req.headers.authorization || '';
    if (!/^Bearer [A-Za-z0-9._~-]+$/i.test(authorization) || authorization.length > 8192) {
      res.setHeader('WWW-Authenticate', 'Bearer');
      return reply(401, { error: 'authentication_required' });
    }
    if (!config) return reply(503, { error: 'api_not_configured' });
    const headers = { apikey: config.key, Authorization: authorization, Accept: 'application/json' };
    const signal = AbortSignal.timeout(8000);
    try {
      // Validate with Auth before querying the user's ERP record.
      const auth = await fetchImpl(`${config.url}/auth/v1/user`, { headers, signal, redirect: 'error' });
      if (auth.status === 401 || auth.status === 403) return reply(401, { error: 'invalid_or_expired_token' });
      if (!auth.ok) return reply(502, { error: 'identity_service_unavailable' });
      const identity = await auth.json();
      if (typeof identity.id !== 'string' || !/^[0-9a-f-]{36}$/i.test(identity.id)) {
        return reply(502, { error: 'invalid_identity_response' });
      }
      const query = new URLSearchParams({
        select: 'id,email,role,tenant_id,employee_id,is_active', id: `eq.${identity.id}`, limit: '1',
      });
      const result = await fetchImpl(`${config.url}/rest/v1/users?${query}`, { headers, signal, redirect: 'error' });
      if (result.status === 401) return reply(401, { error: 'invalid_or_expired_token' });
      if (result.status === 403) return reply(403, { error: 'profile_access_denied' });
      if (!result.ok) return reply(502, { error: 'profile_service_unavailable' });
      const rows = await result.json();
      const user = Array.isArray(rows) && rows.length === 1 ? rows[0] : null;
      if (!user || user.id !== identity.id || user.is_active !== true || !user.tenant_id || !user.role) {
        return reply(403, { error: 'active_erp_account_required' });
      }
      return reply(200, { user: {
        id: user.id, email: user.email, role: user.role, tenant_id: user.tenant_id,
        employee_id: user.employee_id, is_active: true,
      } });
    } catch {
      return reply(502, { error: 'upstream_unavailable' });
    }
  });
}
module.exports = { createApi, configuration };
