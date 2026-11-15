# ظهور تقدم الموظف عند المدير

السبب: نموذج `TeamTask` واستعلام شاشة «فريقي» لم يتضمنا `progress`. نسبة الإنجاز كانت نسبة عدد المهام المكتملة فقط، فتظل صفرًا لمهمة قيد التنفيذ عند 20%. سجل المهام القديم كان يقرأ الحقل دون إظهاره.

التغيير:
- «فريقي»: قراءة التقدم الحالي، عرضه مع حالة كل مهمة وشريط تقدم في القائمة وتفاصيل الموظف. عمود الموظف يعرض متوسط تقدم جميع مهامه بدل الاقتصار على عدد المكتمل.
- «المهام»: إبقاء نسبة المكتمل الحالية وإضافة «متوسط تقدم المهام»، ونسبة كل مهمة قادمة. زر تحديث في رأس الإسناد يقرأ أحدث بيانات الموظف مع الاحتفاظ بمدخلات النموذج.
- سجل المهمة الموجود في الرئيسية: إظهار التقدم الحالي وشريطه بجوار معلومات الاستلام والبدء.
- المتوسط غير موزون: كل مهمة وزنها متساوٍ، والمكتملة 100%. قيم التقدم غير الصالحة صفر، والصحيحة محصورة بين صفر و100. هذا ليس مؤشر تقييم أداء.

القراءة تتم عند فتح الشاشة أو الضغط على التحديث؛ لم يتم إضافة Realtime أو تغيير قاعدة البيانات. لتجربة تحديث أثناء فتح الحسابين: حفظ 20% عند الموظف، تحديث «فريقي» أو «المهام» عند المدير، واختيار الموظف أو فتح تفاصيله. تظل فلاتر المهام القادمة والمتأخرة كما كانت؛ تفاصيل الموظف تعرض جميع مهامه.

الملفات المعدلة:
- `lib/features/manager_team/domain/manager_team_data.dart`
- `lib/features/manager_team/data/manager_team_repo.dart`
- `lib/features/manager_team/view/manager_team_tables.dart`
- `lib/features/manager_team/view/manager_team_page.dart`
- `lib/features/dashboard/view/manager/dashboard_manager.dart`
- `lib/features/dashboard/view/manager/manager_task_assignment.dart`
- `lib/features/dashboard/view/manager/helpers/manager_dashboard_member_metrics_part.dart`
- `lib/features/dashboard/view/dashboard_page_manager_aggregates_part.dart`
- `lib/features/dashboard/view/dashboard_page_manager_timeline_dialog_part.dart`
- `test/manager_team_test.dart`
- `test/manager_team_repo_test.dart`
- `test/manager_task_assignment_test.dart`
- هذا الدليل.

التحقق: 33 اختبارًا نجحت للفريق والإسناد والمرفقات، منها قراءة تقدم 20% من الاستعلام، عرضه وتحديثه إلى 40%، وفصل المتوسط عن نسبة المهام المكتملة، وتخطيط العربية والإنجليزية على أحجام متعددة. `flutter analyze` يعرض 27 ملاحظة سابقة، بدون أخطاء أو ملاحظات جديدة. `git diff --check` نجح. لم ننفذ كتابة في Supabase الفعلي أو رفعًا إلى GitHub.
