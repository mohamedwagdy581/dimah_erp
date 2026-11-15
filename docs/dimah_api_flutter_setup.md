# Flutter current-user API integration

The app still signs in and refreshes sessions with Supabase Auth. AppDI now loads the ERP account through `GET https://api.dimahmusic.com/v1/me` using the current user's access token. Other repositories continue using Supabase.

The response contract is `{ "user": { "id", "email", "role", "tenant_id", "employee_id", "is_active" } }`. The client rejects mismatched identity, missing role/tenant, inactive data, malformed JSON and unexpected status codes. One 401 triggers one session refresh and retry. A server-confirmed inactive/missing ERP account signs out; temporary connectivity failures keep the login and show a retry screen. Requests do not follow redirects or include tokens in query strings.

## Windows app: steps

1. Save the code and stop the currently running Flutter app.
2. Run `flutter pub get` in the project terminal to update the dependency classification for the existing http package.
3. Run `flutter run -d windows`, or start the Windows app again from your IDE.
4. Sign in with an existing ERP account. The app sends its token automatically.
5. Confirm your correct role's home page/menu loads. Sign out and repeat with a different role to check session switching.

No manual token, SQL installation or new password is required. No additional `.env` entry is required: the default API origin is already configured. To change the target later, add `DIMAH_API_URL=https://api.dimahmusic.com` to `.env` and restart.

## Browser app: additional server update

1. Upload and extract `output/deployment/dimah-api-flutter.zip` into `/home/dimahmusic/dimah-api`, replacing app.js, server.js and package.json, with no nested folder.
2. Preserve the existing SUPABASE_URL and SUPABASE_ANON_KEY environment variables. Save and Restart in cPanel Node.js.
3. Local Flutter browser origins (`localhost`, `127.0.0.1`, and `::1`) are supported. Start using `flutter run -d chrome`.
4. For a published web app, add `ALLOWED_ORIGINS` in cPanel with the exact frontend origin, e.g. `https://erp.dimahmusic.com` only if that is its actual deployed address. Multiple origins are comma-separated, without trailing slashes or paths. Save and Restart. Don't use a wildcard.

Browser preflight does not authorize a user; `/v1/me` still requires a valid Bearer token.

## Troubleshooting

- Retry screen: confirm `/health` works, server environment variables are set, the Node application has been restarted, and (for web) the frontend origin is allowed. Retry in the app.
- Postman `/v1/me` succeeds while web fails: check the browser's OPTIONS request and allowed origin.
- No ERP session: confirm the account has an active `public.users` record linked to the Auth user.
- No silent fallback to direct database profile reads occurs; errors stay visible.

## Verification limits

Local mocked Flutter tests cover authenticated request/role mapping, no-session behavior, refresh/retry limit, account revocation, upstream failures, response validation and session switching. Local Node checks cover the existing auth boundary and CORS preflight. The user previously verified the hosted `/v1/me` with Postman. A signed-in Windows/browser run after these changes must still be checked on the user's machine.
