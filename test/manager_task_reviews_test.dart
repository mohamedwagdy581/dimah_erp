import 'dart:async';
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

Map<String, dynamic> task({bool qa = true}) => {
  'id': 'task-1',
  'employee_id': 'e',
  'title': 'عنوان مهمة اختبار',
  'employee_name': 'موظف اختبار',
  'status': qa ? 'done' : 'in_progress',
  'progress': qa ? 100 : 20,
  'qa_status': 'pending',
  'employee_review_status': 'pending',
  'estimate_hours': 6,
  'logged_hours': 5.33,
  'weight': 3,
  'priority': 'high',
  'due_date': '2026-10-15',
  'completed_at': '2026-10-15T07:30:00Z',
  'employee_review_requested_at': '2026-10-15T07:30:00Z',
  'employee_review_note': 'تم إرفاق الملفات ومراجعة التفاصيل.',
  'attachments': [
    {'file_name': 'تقرير.pdf', 'file_url': 'https://example.com/report.pdf'},
  ],
};
void main() {
  test(
    'Delivery decisions preserve task content and return rework to execution',
    () {
      final accepted = managerReviewDecisionPayload(
        task(),
        true,
        '',
        DateTime.utc(2026, 10, 6),
      );
      expect(accepted['qa_status'], 'accepted');
      expect(accepted['employee_review_status'], 'approved');
      expect(accepted.containsKey('title'), false);
      expect(accepted.containsKey('progress'), false);
      final returned = managerReviewDecisionPayload(
        task(),
        false,
        'fix',
        DateTime.utc(2026, 10, 6),
      );
      expect(returned['status'], 'in_progress');
      expect(returned['progress'], 95);
      expect(returned['completed_at'], isNull);
      expect(returned['qa_status'], 'rework');
      final partial = managerReviewDecisionPayload(
        task(qa: false),
        true,
        'checked',
        DateTime.utc(2026, 10, 6),
      );
      expect(partial['employee_review_status'], 'approved');
      expect(partial.containsKey('status'), false);
      expect(partial.containsKey('progress'), false);
      expect(partial.containsKey('qa_status'), false);
    },
  );
  Future<void> pump(
    WidgetTester tester,
    double width,
    String lang, {
    bool qa = true,
    bool empty = false,
    Future<void> Function(Map<String, dynamic>, bool, String)? decision,
    ValueChanged<String>? open,
    GlobalKey? capture,
  }) async {
    tester.view.physicalSize = Size(width, 1200);
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
            body: ManagerTaskReviewsView(
              tasks: empty ? [] : [task(qa: qa)],
              members: const [
                TeamMember(
                  id: 'e',
                  name: 'موظف اختبار',
                  jobTitle: 'أخصائي اختبار',
                ),
              ],
              onRefresh: () {},
              onOpenFile: open ?? (_) {},
              onDecision: decision ?? (_, _, _) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('Review layout $width $lang fits', (tester) async {
        await pump(tester, width, lang);
        expect(tester.takeException(), isNull);
        expect(find.text('أخصائي اختبار'), findsOneWidget);
      });
    }
  }
  testWidgets(
    'Return requires a note, approve delivery permits optional note',
    (tester) async {
      var calls = 0;
      await pump(
        tester,
        1440,
        'ar',
        decision: (_, accept, note) async {
          calls++;
          expect(accept, true);
          expect(note, '');
        },
      );
      await tester.ensureVisible(find.text('إعادة التعديل'));
      await tester.tap(find.text('إعادة التعديل'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('اكتب ملاحظات المراجعة أولًا'), findsOneWidget);
      await tester.tap(find.text('اعتماد التسليم'));
      await tester.pumpAndSettle();
      expect(calls, 1);
    },
  );
  testWidgets(
    'In-progress review preserves actual progress and requires notes',
    (tester) async {
      var calls = 0;
      await pump(
        tester,
        1440,
        'ar',
        qa: false,
        decision: (row, accept, note) async {
          calls++;
          expect(row['progress'], 20);
          expect(accept, true);
          expect(note, 'راجعت التفاصيل');
        },
      );
      expect(find.text('20%'), findsOneWidget);
      await tester.ensureVisible(find.text('اعتماد المراجعة'));
      await tester.tap(find.text('اعتماد المراجعة'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.enterText(find.byType(TextField), 'راجعت التفاصيل');
      await tester.tap(find.text('اعتماد المراجعة'));
      await tester.pumpAndSettle();
      expect(calls, 1);
    },
  );
  testWidgets('Saving disables actions; failure retains notes for retry', (
    tester,
  ) async {
    final pending = Completer<void>();
    await pump(tester, 1440, 'ar', decision: (_, _, _) => pending.future);
    await tester.ensureVisible(find.text('إعادة التعديل'));
    await tester.enterText(find.byType(TextField), 'تحتاج تعديل');
    await tester.tap(find.text('إعادة التعديل'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    pending.completeError(StateError('failed'));
    await tester.pumpAndSettle();
    expect(find.text('تحتاج تعديل'), findsOneWidget);
    expect(
      find.text('تعذر حفظ القرار. حدّث البيانات ثم حاول مرة أخرى.'),
      findsOneWidget,
    );
  });
  testWidgets('Actual attachment URL opens; empty reviews provide refresh', (
    tester,
  ) async {
    String? url;
    await pump(tester, 1440, 'ar', open: (value) => url = value);
    await tester.tap(find.byTooltip('فتح المرفق'));
    expect(url, 'https://example.com/report.pdf');
    url = null;
    await tester.tap(find.byTooltip('تنزيل المرفق'));
    expect(url, 'https://example.com/report.pdf');
    await pump(tester, 1440, 'ar', empty: true);
    expect(find.text('لا توجد مهام بانتظار المراجعة'), findsOneWidget);
  });
  testWidgets('Review desktop preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_REVIEW_PREVIEW')) return;
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
    final key = GlobalKey();
    await pump(tester, 1440, 'ar', capture: key);
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/manager_review_preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
