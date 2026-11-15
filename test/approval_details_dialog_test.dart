import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/approvals/domain/models/approval_request.dart';
import 'package:erp_sys/features/approvals/view/sections/approvals_details_dialog.dart';

ApprovalRequest request({String? runId = 'run', String type = 'payroll_run'}) =>
    ApprovalRequest(
      id: 'request',
      tenantId: 'tenant',
      employeeId: 'employee',
      employeeName: 'المهند السليماني اسم طويل لاختبار عرض الموظف',
      requestType: type,
      status: 'pending',
      createdAt: DateTime(2026, 10, 6),
      payload: {
        'run_id': runId,
        'notes': List.filled(30, 'ملاحظات طويلة للمراجعة ').join(),
      },
    );
final extras = {
  'period_start': '2026-10-01',
  'period_end': '2026-10-31',
  'total_amount': 67200,
  'total_employees': 12,
};
Widget app({
  String lang = 'ar',
  double scale = 1,
  ApprovalRequest? req,
  Future<Map<String, dynamic>> Function()? loader,
  ValueChanged<String>? open,
}) => MaterialApp(
  theme: EmployeeTheme.from(AppTheme.light()),
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showApprovalDetailsDialog(
          context,
          req ?? request(),
          loadExtras: loader ?? () => Future.value(extras),
          onOpenPayroll: open,
        ),
        child: const Text('Open'),
      ),
    ),
  ),
);
Future<void> launch(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  if (const bool.fromEnvironment('EXPORT_APPROVAL_DETAILS')) {
    testWidgets('Export details preview', (tester) async {
      await tester.runAsync(() async {
        for (final entry in {
          'Roboto': 'assets/fonts/DINNextLTArabic-Regular-2.ttf',
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
      await tester.binding.setSurfaceSize(const Size(1000, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final key = GlobalKey();
      await launch(tester, RepaintBoundary(key: key, child: app()));
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/approval_details_preview.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('Details $lang at $width wraps and opens correct payroll', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        String? opened;
        await launch(
          tester,
          app(lang: lang, scale: 1.3, open: (id) => opened = id),
        );
        expect(tester.takeException(), isNull);
        expect(find.textContaining('67,200.00'), findsOneWidget);
        expect(find.text('Total Amount'), findsNothing);
        final button = find.byType(FilledButton);
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(opened, 'run');
        expect(find.byType(AlertDialog), findsNothing);
      });
    }
  }
  testWidgets(
    'Loading and failed details never show invented zero; retry works',
    (tester) async {
      final pending = Completer<Map<String, dynamic>>();
      int loads = 0;
      await tester.pumpWidget(
        app(
          lang: 'en',
          loader: () => ++loads == 1 ? pending.future : Future.value(extras),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Loading details...'), findsOneWidget);
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not load details.'), findsOneWidget);
      expect(find.textContaining('0.00'), findsNothing);
      await tester.ensureVisible(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(loads, 2);
      expect(find.textContaining('67,200.00'), findsOneWidget);
    },
  );
  testWidgets('Missing run cannot navigate; missing amounts are unavailable', (
    tester,
  ) async {
    await launch(
      tester,
      app(req: request(runId: null), loader: () => Future.value({})),
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.textContaining('0.00'), findsNothing);
  });
  testWidgets('Long leave notes scroll and close on a short screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 380));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await launch(
      tester,
      app(
        req: request(type: 'leave'),
        scale: 1.3,
        loader: () => Future.value({}),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
