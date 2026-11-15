# إنشاء حساب الدخول تلقائيًا عند إضافة موظف

## حالة التفعيل

بتاريخ 2026-10-04 أكد المستخدم أن المسار يعمل بعد تنفيذ التفعيل من جهته.
هذه نتيجة تجربة المستخدم؛ لم ينفّذ الوكيل التفعيل أو يفحص المشروع الحي مباشرة.

## الاستخدام بعد التفعيل

من HR → إضافة موظف، أدخل بياناته ثم افتح الخطوة الرابعة «حساب الدخول».
اختر «موظف» أو «مدير مباشر»، وحدد كلمة مرور أولية، ثم اضغط «إنهاء».
لن تظهر رسالة نجاح إلا بعد حفظ الموظف وتجهيز حساب Authentication وربطه بجدول users.
الحساب الجديد يستخدم الإيميل وكلمة المرور المحددين فورًا، ولا يحتاج تأكيد إيميل.
إذا كان الإيميل له حساب Authentication بالفعل، يُربط بنفس الحساب وكلمة مروره الحالية.

القسم يؤخذ من بيانات الموظف. اختيار صلاحية مدير مباشر لا ينقل الموظفين إليه؛
يُسند الموظفون إليه من حقل «المدير المباشر» الموجود في بياناتهم.
لا يُحفظ الباسورد في جدول users أو الملفات أو حالة BLoC.

إذا حُفظ الموظف وفشل تجهيز الدخول، ابقَ في شاشة الإضافة واضغط «إعادة المحاولة».
المحاولة التالية تكمل نفس الموظف والحساب. إذا أغلقت الشاشة، لا تضف نفس الموظف مجددًا؛
مسار استكمال الحساب من ملف موظف محفوظ غير متاح حاليًا.

## تفعيل مرة واحدة على Supabase

### من لوحة Supabase مباشرة

1. افتح `supabase/install_employee_login_provisioning.sql` وانسخ محتواه كله إلى SQL Editor → New query، ثم اضغط Run. النتيجة المتوقعة: Success، بدون صفوف.
2. افتح Edge Functions → Deploy a new function → Via Editor. سمّ الخدمة بالضبط `provision-employee-login`.
3. استبدل محتوى `index.ts` في المحرر بكامل محتوى `supabase/dashboard/provision-employee-login.ts`، ثم اضغط Deploy function.
4. من إعدادات هذه الخدمة فقط عطّل Verify JWT (قد يظهر باسم Verify JWT with legacy secret)، واحفظ. الكود يتحقق من تسجيل الدخول وصلاحية HR/admin بنفسه.
5. أعد تشغيل التطبيق المعدل، وسجّل الدخول بحساب HR/admin، ثم اختبر الإضافة والدخول بإيميل اختبار جديد. لا تضف حساب Authentication يدويًا؛ الخدمة تنشئه.

ملف dashboard نسخة مجمعة من `index.ts` و`provision.ts` للنسخ إلى المحرر دون إضافة ملفات أخرى.
إذا تغير المصدر لاحقًا، يجب إعادة توليد النسخة قبل نشرها من Dashboard.
مرجع النشر من اللوحة: https://supabase.com/docs/guides/functions/quickstart-dashboard

### باستخدام CLI

نفّذ المستخدم التفعيل وأكد نجاح المسار. الخطوات التالية محفوظة لإعداد مشروع آخر؛ لم ينفّذها الوكيل على المشروع الحي.
التصميم الحالي للمشروع وتعديلاته السابقة محفوظان؛ لا توجد تغييرات على جداول البيانات.
لكن التفعيل يضيف دالتين في قاعدة البيانات وخدمة Edge Function، ولذلك يتطلب موافقة مسؤول المشروع.

1. شغّل `supabase/install_employee_login_provisioning.sql` على مشروع ERP الصحيح.
   يضيف `employee_login_context` و`complete_employee_login` فقط، داخل transaction واحدة.
   تشغيلهما متاح لـservice_role فقط؛ يتحققان من دور HR/admin والشركة والبريد والربط قبل الكتابة.
2. انشر خدمة `provision-employee-login` من ملفات `supabase/functions/provision-employee-login/`.
   باستخدام Supabase CLI بعد تسجيل الدخول، من جذر المشروع:

   ```powershell
   supabase functions deploy provision-employee-login --project-ref PROJECT_REF --no-verify-jwt
   ```

   استبدل PROJECT_REF بمعرّف المشروع الصحيح. الخدمة تتحقق من JWT عبر Auth.getUser بنفسها،
   ثم تتحقق من حساب HR/admin الفعال؛ تعطيل فحص البوابة لا يتيح الإنشاء دون تسجيل الدخول.
   تستخدم الخدمة SUPABASE_URL وSUPABASE_SERVICE_ROLE_KEY المتاحين داخل بيئة Supabase فقط.
   لا تُضف مفتاح service_role إلى Flutter ولا ترسله في المحادثة.
3. شغّل نسخة التطبيق المعدلة، ثم اختبر إضافة موظف جديد بإيميل اختبار غير مستخدم،
   واختبر الدخول به. تحقق من ربط `public.users.id = auth.users.id`
   و`public.users.employee_id = public.employees.id` ومن تطابق الشركة والصلاحية.
   اختبر أيضًا مديرًا مباشرًا وحساب Authentication موجودًا سابقًا.

لا تتكرر خطوات التفعيل لكل موظف. ملفات الربط اليدوي السابقة مخصصة لإصلاح السجلات القديمة.
تغيير روابط استعادة كلمة المرور مهمة منفصلة، ولم تتغير إعدادات Site URL في هذه المهمة.

## التحقق المحلي

- `flutter test`: نجحت 24 حالة، تشمل الربط وإعادة المحاولة ومنع الضغط المتكرر واختيار المدير.
- اختبارات منطق الخدمة بـNode: نجحت 8 حالات، تشمل الحساب الموجود ورفض الصلاحيات غير المدعومة.
- `flutter analyze`: بقيت 27 ملاحظة سابقة خارج ملفات هذه المهمة؛ لا ملاحظات جديدة.
- لم يشغّل الوكيل SQL على قاعدة حية أو يفحص الخدمة المنشورة؛ أكد المستخدم نجاح المسار بعد التفعيل من جهته.
- فحص TypeScript هنا يختبر المنطق والتركيب بـNode؛ لا يمثل فحص أنواع Deno أو تشغيل بيئة Supabase.

## ملفات التغيير

- واجهة الإضافة: `lib/features/employees/view/pages/employee_wizard_page.dart` و`view/sections/step_employee_account.dart`.
- حالة الإضافة: `view/cubit/employee_wizard_cubit.dart` و`employee_wizard_state.dart`.
- العقد والنتيجة: `domain/repos/employee_repo.dart` و`domain/models/employee_login_result.dart`.
- الحفظ والربط: `data/repos/employee_repo_impl.dart` و`employee_repo_auth_part.dart`
  و`employee_repo_employee_create_part.dart` و`employee_repo_employee_create_rpc_part.dart`
  و`employee_repo_create_fallback_part.dart` و`employee_login_link.dart`.
- الخدمة: `supabase/config.toml` و`supabase/install_employee_login_provisioning.sql`
  و`supabase/functions/provision-employee-login/index.ts` و`provision.ts` و`provision.test.ts`.
- الاختبارات: `test/employee_provisioning_test.dart`.

مرجع Supabase لإنشاء الحساب من خدمة موثوقة: https://supabase.com/docs/reference/javascript/auth-admin-createuser
