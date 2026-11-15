# ربط حساب الموظف واستعادة كلمة المرور

المستخدم نفّذ ربط حسابه الحالي يدويًا وأكد ظهوره في users. لم ينفّذ الوكيل أي SQL أو تغيير كلمة مرور أو إعدادات على مشروع Supabase الحي.

تم تجهيز مسار إضافة الموظف أو المدير المباشر مع إنشاء وربط حسابه تلقائيًا. يحتاج تفعيلًا واحدًا على Supabase قبل الاستخدام، كما هو موضح في [إنشاء الحساب تلقائيًا](employee_account_provisioning.md). لا تستخدم خطوات الإصلاح اليدوي لكل موظف جديد بعد التفعيل.

## سبب ظهور الموظف وعدم ظهور حساب التطبيق

هناك ثلاثة سجلات مختلفة:

| السجل | الغرض |
| --- | --- |
| auth.users (Authentication → Users) | حساب الدخول وكلمة المرور المخزنة كـhash |
| public.employees | ملف الموظف وقسمه والبيانات الوظيفية |
| public.users | صلاحيات التطبيق والشركة وربط حساب الدخول بالموظف |

يلزم أن يساوي public.users.id قيمة auth.users.id، وأن يساوي public.users.employee_id قيمة public.employees.id، وأن يطابق tenant_id شركة الموظف.

في الكود السابق، create_employee_with_comp ترجع UUID كنص، وكان مسار Dart يرجع مباشرة عند استلام النص، متجاوزًا إنشاء وربط حساب الدخول. الكود الحالي يستخرج المعرّف من النص أو الكائن، ثم BLoC يطلب إنشاء الحساب من خدمة موثوقة. يحتفظ بمعرّف الموظف المحفوظ لإكمال الربط عند إعادة المحاولة داخل نفس شاشة الإضافة.

إنشاء حساب من لوحة Authentication لا ينشئ public.users تلقائيًا بدون trigger أو عملية ربط صريحة. كذلك الحساب الموجود مسبقًا في Auth ولا يملك public.users لا يمكن للعميل العثور على ID الخاص به عبر الجدول العام؛ ملف الإصلاح أدناه يعالج هذه الحالة من SQL Editor.

## إصلاح الحساب الحالي

1. افتح Supabase → SQL Editor وشغّل محتوى supabase/inspect_employee_login.sql. هو استعلام قراءة فقط لحساب البريد الذي أرسله المستخدم.
2. تحقق من auth_user_id، employee_id، tenant_id وdepartment_name. إذا ظهرت عدة سجلات موظف بنفس البريد، راجعها أولًا ولا تضف موظفًا آخر.
3. إذا كان الحساب والموظف موجودين مرة واحدة، شغّل supabase/link_existing_employee_login.sql. يربطهما ويحافظ على الصلاحيات والقسم الحاليين؛ إذا لم يوجد public.users ينشئه بدور employee.
4. تحقق أن department_name هو IT. القسم يأتي من employees.department_id؛ الدور employee هو صلاحية موظف عادي وليس اسم القسم. إذا لم يكن القسم صحيحًا، عدّله من ملف الموظف لدى HR. هذا الملف لا يعيّن مدير IT ولا يغيّر القسم.
5. سجّل خروجًا ثم ادخل بالحساب. لا تعِد إنشاء الموظف.

يتوقف ملف الإصلاح إذا وجد اختلاف شركة، أو ربطًا بموظف آخر، أو تعارضًا في البريد/ID. لا يعدّل auth.users أو كلمة المرور، ولا ينفذ DDL أو تغيير سياسات RLS.

## كلمات مرور الاختبار

لم يُضف عمود لكلمات المرور المكشوفة. Supabase يخزن hash ولا يمكن استخراج كلمة المرور القديمة منه. للاختبار، احتفظ بكلمة المرور في مدير كلمات مرور أو عيّن كلمة جديدة باستخدام Auth Admin API؛ تحديث كلمة المرور لا يحتاج إلى عمود جديد.

تم تجهيز tools/reset_test_password.ps1 للتشغيل المحلي بواسطة مسؤول المشروع:

```powershell
.\tools\reset_test_password.ps1 -ProjectUrl https://PROJECT.supabase.co -UserId AUTH-USER-UUID
```

استبدل URL بعنوان مشروع Supabase، والـUUID بـauth_user_id من استعلام الفحص. الأداة تطلب كلمة المرور دون إظهارها وتحدث حساب Auth فقط. تحتاج متغير الجلسة المحلي SUPABASE_SERVICE_ROLE_KEY؛ لا تضفه لملف .env المضمّن في Flutter، ولا تضعه في Git أو ترسله في المحادثة. الأداة لا تحفظ كلمة المرور في أي ملف أو جدول. لم يتم تشغيل هذه الأداة على حساب حقيقي.

## إصلاح رابط الاستعادة

### إصلاح الشاشة الحمراء عند فتح الرابط

في 2026-10-04 وصلت نتيجة الاستعادة إلى التطبيق بصيغة `#error=access_denied&error_code=otp_expired`.
سبب الشاشة الحمراء أن HashUrlStrategy كان يمرر بيانات Auth الموجودة بعد # إلى go_router كمسار صفحة غير صالح.
تم إضافة استراتيجية hash تستثني بيانات Auth مع الحفاظ على مسارات التطبيق الحالية مثل `#/my?tab=tasks`.

في نسخة الويب، تتم معالجة رابط Auth مرة واحدة قبل تشغيل الراوتر. روابط لوحة Supabase التي تحتوي access_token
تستخدم implicit flow، وروابط code تستخدم PKCE. يُحفظ نوع الاستعادة الناتج لإظهار شاشة تغيير كلمة المرور بعد نجاح التحقق.
لا تُحفظ الرموز أو الوصف الخام للخطأ في حالة التطبيق. الخطأ يعرض صفحة عربية/إنجليزية واضحة متاحة بدون تسجيل دخول،
حتى لو كان هناك حساب آخر مسجل مسبقًا. زر المتابعة يلغي حالة خطأ الرابط ويعود لمسار الدخول المعتاد.

ظهور otp_expired يعني أن الرابط غير صالح أو انتهت صلاحيته؛ إصلاح الواجهة لا يعيد صلاحية الرابط.
اطلب رسالة استعادة جديدة وافتح أحدث رسالة مرة واحدة، بعد تحديث المتصفح باستخدام Ctrl+Shift+R.
لم يرسل الوكيل أي رسالة استعادة أو يغير كلمة مرور أو إعدادات Supabase.

التحقق: نجحت 46 حالة في `flutter test`، وبقيت 27 ملاحظة سابقة في `flutter analyze` دون ملاحظات جديدة.
أُعيد تشغيل نسخة الويب المعدلة على المنفذ 3000، ونجح تجميعها. لم تُختبر رحلة الإيميل الحقيقية على حساب المستخدم.
اختبار استراتيجية hash داخل متصفح فعلي تعلّق أثناء تحميل منصة الاختبار في Edge وChrome، وتم تنظيف عملياته المؤقتة؛
لذلك لا يُحسب ضمن الاختبارات الناجحة. اختباراته موجودة في `test/auth_hash_strategy_web_test.dart` ومقيّدة بمنصة browser.

ملفات هذا الإصلاح:

- `lib/main.dart`
- `lib/core/auth/auth_link_callback.dart`
- `lib/core/auth/auth_url_strategy.dart`
- `lib/core/auth/auth_url_strategy_stub.dart`
- `lib/core/auth/auth_url_strategy_web.dart`
- `lib/core/auth/auth_notifier.dart`
- `lib/core/routing/app_router.dart`
- `lib/core/routing/app_router_redirect_part.dart`
- `lib/core/routing/app_routes.dart`
- `lib/features/auth/view/auth_link_error_page.dart`
- `pubspec.yaml` و`pubspec.lock` (إضافة Flutter Web SDK فقط)
- `test/auth_link_callback_test.dart`
- `test/auth_hash_strategy_web_test.dart`
- `docs/employee_login_recovery.md`

### الاستعادة داخل تطبيق Windows (الحل الدائم — 2026-10-11)

أضيفت صفحة `/recover-password` وزر «نسيت كلمة المرور؟» في تسجيل الدخول.
ترسل رسالة الاستعادة عبر `resetPasswordForEmail` وتتحقق من الكود عبر `verifyOTP(type: OtpType.recovery)`.
بعد التحقق يفتح التطبيق شاشة كلمة المرور الجديدة، ثم يسجل الخروج بعد حفظها.
لا يُنشئ هذا المسار حسابات جديدة ولا يحتاج خادمًا على localhost أو تغيير Site URL.

**إعداد مرة واحدة:** في مشروع Supabase الصحيح، افتح Authentication → Email Templates → Reset Password.
انسخ محتوى `supabase/dashboard/reset-password-email.html` إلى Body واحفظ القالب.
القالب يحتوي `{{ .Token }}` ويعرض الكود مباشرة بدون رابط يتطلب متصفحًا.
لو عنوان القسم في لوحة Supabase تغيّر، ابحث عن قالب رسالة **Reset Password** داخل إعدادات Authentication.
لم يتم تعديل هذا القالب في المشروع المستضاف بواسطة الوكيل؛ يجب حفظه من لوحة المشروع.

بعد Hot Restart: افتح «نسيت كلمة المرور؟»، أدخل البريد، اطلب كودًا جديدًا، ثم أدخله داخل التطبيق.
يمكن أيضًا استخدام كود رسالة أُرسلت من لوحة Supabase، لكن يجب أن يكون القالب الجديد محفوظًا أولًا.
إذا كان لديك كود بالفعل، أدخل نفس البريد واضغط إرسال، ثم استخدم كود **أحدث** رسالة.
لا تستخدم روابط الرسائل القديمة لهذا المسار؛ لا تعِد إرسال الكود أثناء انتظار الرسالة إلا بعد انتهاء مهلة إعادة الإرسال.
رسائل الخطأ لا تعرض أكوادًا أو مفاتيح، والكود يظل في الذاكرة فقط ويُمسح عند التحقق أو إغلاق الصفحة.
إعادة الإرسال محددة بمهلة 60 ثانية داخل الواجهة، وحدود Supabase وتاريخ انتهاء الكود تظل هي المرجع النهائي.

المراجع الرسمية:
- https://supabase.com/docs/guides/auth/auth-email-templates
- https://supabase.com/docs/reference/dart/auth-verifyotp

### تشخيص رابط الويب المحلي القديم

الرابط وصل إلى `http://localhost:3000` والمتصفح أظهر `ERR_CONNECTION_REFUSED`.
هذا يعني أن التطبيق غير متاح على ذلك المنفذ؛ شاشة الاستعادة لا يمكن تحميلها قبل الوصول إلى التطبيق.
لتجربة الرابط على نفس جهاز التطوير، شغّل نسخة الويب من جذر المشروع واتركها تعمل:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3000
```

بعد ظهور عنوان الخادم جرّب فتح `http://localhost:3000` أولًا، ثم أرسل رسالة استعادة جديدة من Supabase وافتحها على نفس الجهاز.
تشغيل نسخة Windows وحدها لا يشغّل خادم ويب على المنفذ 3000.
هذه طريقة اختبار محلية فقط. للمستخدمين على أجهزة أخرى، اضبط Authentication → URL Configuration → Site URL
على عنوان HTTPS منشور يستضيف نسخة الويب المعدلة، وأضف عنوان التحويل المناسب إلى Redirect URLs.
لا تغيّر Site URL إلى دومين الشركة إلا إذا كانت نسخة التطبيق وصفحة الاستعادة تعملان فعليًا عليه.
لم يتم تعديل إعدادات URL على Supabase، ولم يتم إرسال رسالة استعادة بواسطة الوكيل.

الكود الآن يتعامل مع حدث passwordRecovery ويعرض /reset-password خارج واجهة التطبيق التي تعتمد على public.users. بعد حفظ كلمة المرور الجديدة، يسجل الخروج للعودة إلى تسجيل الدخول. صفحة تغيير كلمة المرور العادية تظل متاحة داخل التطبيق.

إعدادات Supabase المطلوبة تعتمد على منصة التشغيل:

- للويب: Authentication → URL Configuration → Site URL يجب أن يكون عنوان تطبيق Flutter الذي يستطيع المستخدم الوصول إليه، مع إضافة عناوين التحويل المستخدمة إلى Redirect URLs. لا تستخدم localhost لمستخدمين على أجهزة أخرى. عند إرسال رابط الاستعادة من Dashboard، راجع Site URL وقالب Reset Password.
- لـWindows أو الهاتف: رابط HTTPS لا يفتح التطبيق المحلي وحده؛ يلزم عنوان ويب متاح أو إعداد deep link للتطبيق والمنصة. لم يتم افتراض عنوان أو إنشاء إعداد deep link دون معرفة منصة الاستخدام.
- عندما يكون Site URL موقعًا محليًا للتطوير، يجب أن يكون خادم التطوير يعمل على الجهاز الذي يفتح الرابط وعلى المنفذ الصحيح. لإرسال الإيميلات لمستخدمين خارجيين، استخدم عنوانًا متاحًا لهم.
- بعد تصحيح إعدادات التحويل، أرسل رابط استعادة جديد. لا تشارك الرابط نفسه، لأنه يحتوي رمز استعادة/دخول.

لم يتم التحقق من إعدادات المشروع الحي أو نجاح رحلة الإيميل كاملة؛ يلزم عنوان Site URL الحالي، ومنصة الاستخدام، ونتيجة SQL الفحص، بدون كلمات مرور أو مفاتيح أو رموز دخول.

## الملفات الخاصة بهذه المهمة

- lib/core/auth/auth_notifier.dart
- lib/core/routing/app_routes.dart
- lib/core/routing/app_router.dart
- lib/core/routing/app_router_redirect_part.dart
- lib/features/employees/data/repos/employee_login_link.dart
- lib/features/employees/data/repos/employee_repo_impl.dart
- lib/features/employees/data/repos/employee_repo_employee_create_rpc_part.dart
- lib/features/employees/data/repos/employee_repo_employee_create_part.dart
- lib/features/profile/view/change_password_page.dart
- supabase/inspect_employee_login.sql
- supabase/link_existing_employee_login.sql
- tools/reset_test_password.ps1
- test/employee_login_link_test.dart
- docs/employee_login_recovery.md

تعديلات تصميم الموظف السابقة محفوظة.

## مصادر Supabase

- إدارة بيانات المستخدم: https://supabase.com/docs/guides/auth/managing-user-data
- تخزين كلمات المرور: https://supabase.com/docs/guides/auth/password-security
- روابط التحويل: https://supabase.com/docs/guides/auth/redirect-urls
- تغيير كلمة المرور إداريًا: https://supabase.com/docs/reference/javascript/auth-admin-updateuserbyid

## نتيجة التحقق

- flutter test: نجحت الاختبارات الـ17، ومنها 7 اختبارات جديدة لربط الموظف والتعامل مع حدث الاستعادة وحفظ كلمة المرور.
- flutter analyze: لا أخطاء أو ملاحظات في ملفات هذه المهمة؛ بقيت 27 ملاحظة سابقة في ملفات أخرى، لذلك خرج الأمر بالرمز 1.
- تم فحص تركيب أداة PowerShell دون تشغيلها على حساب فعلي.
- git diff --check: نجح.
- لم تُنفذ ملفات SQL على Supabase الحي، ولم يُرسل إيميل أو يُغيّر أي حساب، ولم يُرفع شيء إلى GitHub.
