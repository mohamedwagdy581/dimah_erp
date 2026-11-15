# دمج الإجازات مع طلباتي للموظف

أزيل عنصر «إجازاتي» من قائمة الموظف وتبويبات بوابته فقط. حسابات الموارد البشرية والمدير تحتفظ بتبويباتها. رابط الموظف القديم `/my?tab=leaves` يعرض طلباتي، وبطاقة رصيد الإجازات في الرئيسية تنتقل إلى طلباتي.

أعلى نموذج الطلب وسجل الطلبات تظهر بطاقات رصيد لكل نوع مُسجّل: المستحق والمستخدم والمتبقي والسنة. البطاقات تتسع حسب العدد وعرض الشاشة وتكبير الخط. أزيلت بطاقة الرصيد المكررة داخل النموذج عند عرض الملخص الجديد.

الرصيد يأتي من `LeavesRepo.fetchLeaveBalances` لنفس الموظف والسنة الحالية أو سنة بداية الطلب المختارة. لا توجد بيانات تجريبية في التطبيق، ولا يجري احتساب رصيد بديل. الرصيد المفقود أو المتعذر تحميله له رسالة واضحة وزر تحديث، والمتبقي السالب يظهر كما ورد من البيانات. يُحدّث الرصيد بعد إرسال الطلب أو العودة من إعادة تقديمه.

## الملفات المعدّلة

- `lib/features/shell/view/sections/sidebar_section.dart`
- `lib/features/shell/view/utils/shell_title_resolver.dart`
- `lib/features/dashboard/view/employee/sections/employee_dashboard_summary_section.dart`
- `lib/features/employee_portal/view/pages/employee_portal_page.dart`
- `lib/features/employee_portal/view/widgets/employee_portal/employee_portal_tabs.dart`
- `lib/features/employee_portal/view/sections/employee_requests_section.dart`
- `lib/features/employee_portal/view/cubit/employee_leave_request_cubit.dart`
- `lib/features/employee_portal/view/widgets/employee_requests/employee_leave_balances.dart` (جديد)
- `lib/features/employee_portal/view/widgets/employee_requests/employee_leave_request_view.dart`
- `lib/features/employee_portal/view/widgets/employee_requests/employee_request_history_view.dart`
- `test/employee_requests_test.dart`
- `test/widget_test.dart`
- هذا التقرير.

## التحقق

- نجحت 57 حالة اختبار للطلبات والسجل والتنقل؛ وبعد تحسين توزيع البطاقات نجحت اختبارات الطلبات الثلاثون مجددًا.
- مراجعة المعاينة `build/employee_requests_preview.png` ببيانات اختبار، والتحقق من العربية والإنجليزية وعروض 320 و768 و1440 وتكبير النص إلى 150%.
- `flutter analyze`: 27 ملاحظة سابقة، دون أخطاء جديدة.
- لم تتغير قاعدة البيانات ولم تُرفع التعديلات إلى GitHub. تصميم الحضور والانصراف هو الخطوة التالية.
