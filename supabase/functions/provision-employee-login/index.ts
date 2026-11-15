import { createClient } from 'npm:@supabase/supabase-js@2';
import { provisionEmployeeLogin, ProvisionError, loginContextError, type LoginContext } from './provision.ts';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const reply = (status: number, body: unknown) => new Response(JSON.stringify(body), {
  status, headers: { ...cors, 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
});

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return reply(405, { message: 'Method not allowed' });
  const bearer = req.headers.get('Authorization');
  if (!bearer?.startsWith('Bearer ')) return reply(401, { message: 'سجّل الدخول أولًا' });
  const url = Deno.env.get('SUPABASE_URL');
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) return reply(503, { message: 'خدمة إنشاء الحسابات غير مهيأة' });
  const admin = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
  try {
    const { data: { user }, error: authError } = await admin.auth.getUser(bearer.slice(7));
    if (authError || !user) return reply(401, { message: 'انتهت جلسة الدخول؛ سجّل الدخول مجددًا' });
    const { data: actor, error: actorError } = await admin.from('users')
      .select('role, is_active').eq('id', user.id).maybeSingle();
    if (actorError || !actor || !actor.is_active || !['admin', 'hr'].includes(actor.role)) {
      return reply(403, { message: 'إنشاء الحسابات متاح لمسؤول النظام وHR فقط' });
    }
    const input = await req.json().catch(() => null);
    if (input?.action === 'check') {
      const { data, error } = await admin.rpc('hr_employee_creation_ready', { p_actor_id: user.id });
      if (error || data?.ready !== true || data?.version !== 2) {
        return reply(503, { code: 'setup_required', message: 'إعداد إضافة الموظف وحساب الدخول غير مكتمل. شغّل ملفات إعداد إنشاء الموظف وربط الحساب ثم حدّث خدمة provision-employee-login.' });
      }
      return reply(200, data);
    }
    const result = await provisionEmployeeLogin(input, {
      context: async (employeeId) => {
        const { data, error } = await admin.rpc('employee_login_context', { p_actor_id: user.id, p_employee_id: employeeId });
        if (error) {
          throw loginContextError(error);
        }
        return data as LoginContext;
      },
      createAuth: async (context, password) => {
        const { data, error } = await admin.auth.admin.createUser({
          email: context.email, password, email_confirm: true,
          user_metadata: { name: context.name },
        });
        if (error) {
          if (['email_exists', 'user_already_exists'].includes(error.code ?? '')) return null;
          throw new ProvisionError(400, 'auth_create_failed',
            'تعذّر إنشاء حساب الدخول. تحقق من الإيميل وسياسة كلمة المرور في Supabase');
        }
        return data.user.id;
      },
      complete: async (employeeId, authUserId, role) => {
        const { error } = await admin.rpc('complete_employee_login', {
          p_actor_id: user.id, p_employee_id: employeeId, p_auth_user_id: authUserId, p_role: role,
        });
        if (error) throw new ProvisionError(409, 'link_failed', 'تم تجهيز حساب الدخول لكن تعذّر الربط؛ أعد المحاولة لنفس الموظف');
      },
    });
    return reply(200, result);
  } catch (error) {
    if (error instanceof ProvisionError) return reply(error.status, { code: error.code, message: error.message });
    // Do not log request bodies, passwords, JWTs or service keys.
    return reply(500, { message: 'خدمة إنشاء الحسابات غير متاحة حاليًا؛ أعد المحاولة' });
  }
});
