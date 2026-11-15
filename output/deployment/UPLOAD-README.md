# DIMAH API hosting check

Extract dimah-api-auth.zip directly into /home/dimahmusic/dimah-api using cPanel File Manager.
app.js, server.js and package.json must be directly inside that folder, with no nested dimah-api folder.
If cPanel created a sample app.js, replace that sample with this app.js.
Keep the application's existing Passenger configuration and node_modules link.
Return to Node.js and click Restart.

Open https://api.dimahmusic.com/health. Expected JSON:
{"status":"ok","service":"dimah-api"}

This starter uses Node.js built-in modules only. No NPM installation is needed.
In cPanel Node.js > Environment variables add SUPABASE_URL and SUPABASE_ANON_KEY.
Copy their existing values from the Flutter project's .env privately. Use the anon or publishable key, never a service_role or secret key.
Click Save, then Restart. No SQL installation is required.

GET /v1/me without a Bearer token returns 401 authentication_required.
With a valid Supabase access token, it validates identity with Supabase Auth then fetches only that user's active ERP account using the same token and existing RLS.
No employee ID or tenant ID from the request is accepted. It changes no records.
Missing configuration returns 503, expired tokens return 401, inactive or missing ERP accounts return 403, upstream failures return 502.
The public health endpoint confirms the process is alive, not Supabase connectivity.

Import DIMAH-ERP.postman_collection.json in your own Postman workspace.
Set base_url, supabase_url and supabase_anon_key locally. Send request 1 and request 2 first.
For request 3 enter your existing account email/password locally, then copy the response access_token into a local Postman environment variable named access_token for request 4.
Do not share that response or save/publish your password. Clear the password from the request after testing.
If your account requires MFA, use a valid MFA-completed session instead; this basic password request does not implement MFA.
Tokens expire; sign in again for a fresh token. Existing Flutter login remains unchanged.
Flutter now loads the session profile through this API; HR/payroll operations still use the existing repositories.
The dimah-api-flutter.zip update adds browser preflight support for localhost and configured ALLOWED_ORIGINS. See docs/dimah_api_flutter_setup.md.
Keep secrets out of uploads and the public document root.
HTTPS redirect is a separate hosting setting; verify it before connecting real app traffic.
