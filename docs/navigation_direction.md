# اتجاه التالي والسابق

وفق تفضيل المستخدم: السهم الأيمن ينفذ التالي، والسهم الأيسر ينفذ السابق، في العربية والإنجليزية. يشمل ذلك الشهور وترقيم الصفحات. السجلات تبقى بالأحدث أولًا؛ الصفحة التالية تعرض سجلات أقدم، والشهر التالي يزيد الشهر فعلًا (أكتوبر إلى نوفمبر).

تم تثبيت ترتيب مجموعة الأزرار واتجاه أيقوناتها فقط، مع الحفاظ على RTL لباقي الصفحة والنص العربي. المكوّن `PageNavigationButtons` يوحّد ذلك في أشرطة ترقيم الصفحات المشتركة.

التحقق: 41 اختبارًا للحضور وسجل الطلبات والأزرار المشتركة نجحت. اختبارات اللغتين تنقر الزر الموجود فعليًا على اليمين وتتحقق من تقدم الصفحة/الشهر، وتتحقق من رجوع الزر الأيسر وحدود الصفحات. تمت مراجعة معاينة الحضور بصريًا. `flutter analyze`: 27 ملاحظة وتحذيرًا سابقة دون أخطاء جديدة. `git diff --check` ناجح.

الملفات الجديدة:

- `lib/core/widgets/page_navigation_buttons.dart`
- `test/page_navigation_buttons_test.dart`
- `docs/navigation_direction.md`

الملفات المعدّلة:

- `lib/features/employee_portal/view/widgets/employee_attendance_view.dart`
- `lib/features/employee_portal/view/widgets/employee_requests/employee_request_history_view.dart`
- `test/employee_attendance_test.dart`
- `lib/features/accounting/journal/view/widgets/journal_pagination_bar.dart`
- `lib/features/accounting/accounts/view/widgets/accounts_pagination_bar.dart`
- `lib/features/approvals/view/widgets/approvals_pagination_bar.dart`
- `lib/features/payroll/view/widgets/payroll_pagination_bar.dart`
- `lib/features/attendance/view/widgets/attendance_pagination_bar.dart`
- `lib/features/departments/view/widgets/departments_pagination_bar.dart`
- `lib/features/employees/view/widgets/employees_pagination_bar.dart`
- `lib/features/employee_docs/view/widgets/employee_docs_pagination_bar.dart`
- `lib/features/leaves/view/widgets/leaves_pagination_bar.dart`
