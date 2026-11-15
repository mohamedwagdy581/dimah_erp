import 'dart:io';
import 'dart:ui' as ui;
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/features/dashboard/view/dashboard_page.dart';
import 'package:erp_sys/features/manager_team/domain/manager_team_data.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class Harness extends StatefulWidget {
  const Harness({
    super.key,
    this.selected = true,
    this.saving = false,
    this.retry = false,
  });
  final bool selected, saving, retry;
  @override
  State<Harness> createState() => HarnessState();
}

class HarnessState extends State<Harness> {
  final title = TextEditingController(),
      description = TextEditingController(),
      hours = TextEditingController(text: '6');
  String? employee;
  String type = 'report', priority = 'high';
  DateTime? due;
  int submits = 0;
  String? attachment;
  @override
  void initState() {
    super.initState();
    employee = widget.selected ? 'e1' : null;
    due = widget.selected ? DateTime(2026, 10, 15) : null;
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    hours.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ManagerTaskAssignmentView(
    members: const [
      TeamMember(id: 'e1', name: 'موظف اختبار', jobTitle: 'أخصائي اختبار'),
      TeamMember(id: 'e2', name: 'Second member with a long name'),
    ],
    activeTasks: const {'e1': 4, 'e2': 0},
    completion: const {'e1': .4, 'e2': 0},
    averageProgress: const {'e1': .2, 'e2': 0},
    upcoming: const [
      {
        'employee_id': 'e1',
        'title': 'مهمة قادمة من البيانات',
        'due_date': '2026-10-10',
        'progress': 20,
      },
    ],
    taskTypes: const {'report': 'تقرير', 'general': 'عام'},
    title: title,
    description: description,
    hours: hours,
    employeeId: employee,
    taskType: type,
    priority: priority,
    dueDate: due,
    saving: widget.saving,
    attachmentName: attachment,
    attachmentBytes: attachment == null ? null : 1024,
    attachmentRetry: widget.retry,
    onPickAttachment: () => setState(() => attachment = 'brief.pdf'),
    onRemoveAttachment: () => setState(() => attachment = null),
    onEmployee: (v) => setState(() => employee = v),
    onType: (v) => setState(() => type = v!),
    onPriority: (v) => setState(() => priority = v!),
    onDate: () => setState(() => due = DateTime(2026, 10, 15)),
    onSubmit: () async {
      submits++;
    },
    onCancel: () => setState(() {
      employee = null;
      due = null;
      title.clear();
      description.clear();
      hours.text = '8';
    }),
    onWeight: (_, _) async => 3,
  );
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    double width,
    String lang, {
    GlobalKey<HarnessState>? state,
    bool selected = true,
    bool saving = false,
    bool retry = false,
    GlobalKey? capture,
  }) async {
    tester.view.physicalSize = Size(width, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(lang),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: EmployeeTheme.from(AppTheme.light()),
        home: RepaintBoundary(
          key: capture,
          child: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1100),
                textScaler: TextScaler.linear(width < 500 ? 1.3 : 1),
              ),
              child: Harness(
                key: state,
                selected: selected,
                saving: saving,
                retry: retry,
              ),
            ),
          ),
        ),
      ),
    );
    if (saving) {
      await tester.pump(const Duration(milliseconds: 100));
    } else {
      await tester.pumpAndSettle();
    }
  }

  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('Assignment layout $width $lang fits without overflow', (
        tester,
      ) async {
        await pump(tester, width, lang);
        expect(find.text('أخصائي اختبار'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('Attachment selection and removal retain task inputs', (
    tester,
  ) async {
    final key = GlobalKey<HarnessState>();
    await pump(tester, 1440, 'ar', state: key);
    key.currentState!.title.text = 'Test task';
    await tester.tap(find.text('إضافة مرفق'));
    await tester.pumpAndSettle();
    expect(find.text('brief.pdf'), findsOneWidget);
    expect(find.text('0.00 MB'), findsOneWidget);
    await tester.tap(find.byTooltip('إزالة المرفق'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة مرفق'), findsOneWidget);
    expect(key.currentState!.title.text, 'Test task');
  });
  testWidgets(
    'Attachment retry bypasses reassignment validation and locks task fields',
    (tester) async {
      final key = GlobalKey<HarnessState>();
      await pump(tester, 1440, 'ar', state: key, retry: true);
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
        isFalse,
      );
      await tester.tap(find.text('إعادة رفع المرفق'));
      await tester.pumpAndSettle();
      expect(key.currentState!.submits, 1);
      expect(find.text('اكتب عنوان المهمة'), findsNothing);
    },
  );
  testWidgets(
    'Invalid values block assignment; Arabic hours normalize before submit',
    (tester) async {
      final key = GlobalKey<HarnessState>();
      await pump(tester, 1440, 'ar', state: key);
      await tester.tap(find.text('إسناد المهمة'));
      await tester.pumpAndSettle();
      expect(key.currentState!.submits, 0);
      expect(find.text('اكتب عنوان المهمة'), findsOneWidget);
      key.currentState!.title.text = 'مهمة حقيقية';
      key.currentState!.hours.text = '-1';
      await tester.tap(find.text('إسناد المهمة'));
      await tester.pumpAndSettle();
      expect(key.currentState!.submits, 0);
      key.currentState!.hours.text = '٦٫٥';
      await tester.tap(find.text('إسناد المهمة'));
      await tester.pumpAndSettle();
      expect(key.currentState!.submits, 1);
      expect(key.currentState!.hours.text, '6.5');
    },
  );
  testWidgets(
    'Employee and date are required; cancel clears selected workload',
    (tester) async {
      final key = GlobalKey<HarnessState>();
      await pump(tester, 1440, 'ar', state: key, selected: false);
      key.currentState!.title.text = 'عنوان';
      await tester.tap(find.text('إسناد المهمة'));
      await tester.pumpAndSettle();
      expect(key.currentState!.submits, 0);
      expect(find.text('اختر موظفًا من فريقك'), findsOneWidget);
      expect(find.text('اختر تاريخ الاستحقاق'), findsOneWidget);
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(key.currentState!.title.text, '');
      expect(find.text('اختر موظفًا لعرض المهام الموكلة إليه'), findsOneWidget);
    },
  );
  testWidgets('Saving disables assignment and cancel', (tester) async {
    await pump(tester, 1440, 'ar', saving: true);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    final cancel = find.widgetWithText(OutlinedButton, 'إلغاء');
    expect(tester.widget<OutlinedButton>(cancel).onPressed, isNull);
  });
  testWidgets('Selected employee summary displays partial progress', (
    tester,
  ) async {
    await pump(tester, 1440, 'ar');
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('التقدم: 20%'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
  });
  testWidgets('Assignment desktop preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_ASSIGNMENT_PREVIEW')) return;
    await tester.runAsync(() async {
      for (final entry in {
        'Roboto': 'C:/Windows/Fonts/segoeui.ttf',
        'MaterialIcons':
            'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(entry.key)..addFont(
              Future.value(
                ByteData.sublistView(await File(entry.value).readAsBytes()),
              ),
            ))
            .load();
      }
    });
    final capture = GlobalKey(), state = GlobalKey<HarnessState>();
    await pump(tester, 1440, 'ar', state: state, capture: capture);
    state.currentState!.title.text = 'عنوان مهمة اختبار';
    state.currentState!.description.text =
        'وصف يوضح المطلوب من الموظف ومخرجات المهمة.';
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/manager_assignment_preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
  testWidgets('Choosing another employee updates workload and upcoming tasks', (
    tester,
  ) async {
    await pump(tester, 1440, 'ar');
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second member with a long name').last);
    await tester.pumpAndSettle();
    expect(find.text('مهمة قادمة من البيانات'), findsNothing);
    expect(find.text('لا توجد مهام مستحقة خلال ٧ أيام'), findsOneWidget);
    expect(find.text('0%'), findsNWidgets(2));
  });
}
