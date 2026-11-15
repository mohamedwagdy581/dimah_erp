// Dashboard deployment copy. Generated from functions/provision-employee-login/index.ts and provision.ts.
// Paste the entire file into the Dashboard index.ts. Function name: provision-employee-login.
import { createClient } from 'npm:@supabase/supabase-js@2';
export type LoginRole = 'employee' | 'manager';
export type LoginContext = {
  employeeId: string;
  tenantId: string;
  email: string;
  name: string;
  authUserId: string | null;
};
export type ProvisionInput = { employeeId: string; role: LoginRole; initialPassword?: string };
export type ProvisionPorts = {
  context: (employeeId: string) => Promise<LoginContext>;
  createAuth: (context: LoginContext, password: string) => Promise<string | null>;
  complete: (employeeId: string, authUserId: string, role: LoginRole) => Promise<void>;
};
export class ProvisionError extends Error {
  status: number;
  code: string;
  constructor(status: number, code: string, message: string) { super(message); this.status = status; this.code = code; }
}

export async function provisionEmployeeLogin(input: ProvisionInput, ports: ProvisionPorts) {
  if (!input || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(input.employeeId ?? '')) {
    throw new ProvisionError(400, 'invalid_employee', 'معرّف الموظف غير صحيح');
  }
  if (!['employee', 'manager'].includes(input.role)) {
    throw new ProvisionError(400, 'invalid_role', 'اختر موظفًا أو مديرًا مباشرًا');
  }
  const context = await ports.context(input.employeeId);
  let authId = context.authUserId;
  let accountCreated = false;
  if (!authId) {
    const password = input.initialPassword;
    if (typeof password !== 'string' || password.length < 12 || !/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/[0-9]/.test(password) || !/[^A-Za-z0-9]/.test(password)) {
      throw new ProvisionError(400, 'weak_password', 'كلمة المرور تحتاج 12 حرفًا على الأقل، وحروفًا كبيرة وصغيرة ورقمًا ورمزًا');
    }
    authId = await ports.createAuth(context, password);
    accountCreated = authId !== null;
    // A concurrent request may have created the account. Never reset its password.
    if (!authId) authId = (await ports.context(input.employeeId)).authUserId;
    if (!authId) throw new ProvisionError(409, 'auth_not_ready', 'تعذّر تجهيز حساب الدخول؛ أعد المحاولة');
  }
  await ports.complete(input.employeeId, authId, input.role);
  return { employeeId: input.employeeId, email: context.email, role: input.role, accountCreated };
}

// Translate known SQL failures without exposing database details or guessing their cause.
export function loginContextError(error: { code?: string; message?: string }): ProvisionError {
  const message = error.message ?? '';
  if (message.includes('Inactive employee cannot provision login')) return new ProvisionError(403, 'inactive_employee',
    'الموظف غير نشط. أعد تفعيله قبل تجهيز حساب الدخول.');
  if (message.includes('Duplicate employee email')) return new ProvisionError(409, 'duplicate_employee_email',
    'الإيميل مسجل لأكثر من موظف. راجع السجلات المكررة قبل تجهيز الحساب.');
  if (message.includes('Multiple Auth accounts')) return new ProvisionError(409, 'duplicate_auth_email',
    'يوجد أكثر من حساب Auth بنفس الإيميل. يلزم مراجعة الحسابات قبل الربط.');
  if (message.includes('Account is already assigned')) return new ProvisionError(409, 'existing_account_conflict',
    'يوجد سجل حساب بنفس الإيميل لكن الربط أو الشركة أو الصلاحية غير متوافق. افحص سجل users وAuth قبل الربط.');
  if (message.includes('Conflicting application accounts')) return new ProvisionError(409, 'duplicate_app_account',
    'يوجد تعارض بين سجلات users الخاصة بهذا الإيميل. يلزم مراجعتها قبل الربط.');
  if (message.includes('Employee is outside')) return new ProvisionError(403, 'employee_scope',
    'الموظف غير موجود في شركة حساب HR الحالي. تحقق من الشركة التي سجلت الدخول عليها.');
  if (message.includes('Only active HR')) return new ProvisionError(403, 'actor_forbidden',
    'حسابك الحالي غير مخول بإنشاء حسابات الموظفين أو غير نشط.');
  if (message.includes('Employee email is required')) return new ProvisionError(400, 'missing_email',
    'أضف إيميلًا للموظف في ملفه أولًا.');
  if (['PGRST202', '42883', '42P01', '42703'].includes(error.code ?? '')) return new ProvisionError(503, 'login_setup_required',
    'إعداد دوال ربط الحساب أو الجداول غير مكتمل. أعد تشغيل ملف install_employee_login_provisioning.sql.');
  return new ProvisionError(error.code === '42501' ? 403 : 409, 'login_context_failed',
    'تعذر فحص ربط الحساب. شغّل ملف تشخيص تعارض حساب الموظف لمعرفة السبب.');
}

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

