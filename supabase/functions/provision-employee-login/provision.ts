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

