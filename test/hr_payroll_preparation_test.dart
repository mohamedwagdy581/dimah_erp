import 'dart:io';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/payroll/domain/models/payroll_item.dart';
import 'package:erp_sys/features/payroll/domain/repos/payroll_repo.dart';
import 'package:erp_sys/features/payroll/view/widgets/payroll_preparation_view.dart';

class PreparationRepo implements PayrollRepo {
  int creates = 0;
  int sends = 0;
  bool failSubmit = false;
  final items = List.generate(
    5,
    (i) => PayrollItem(
      id: '$i',
      runId: '',
      employeeId: '$i',
      employeeName: [
        'سارة أحمد',
        'عبدالله محمد',
        'نورة علي',
        'محمد خالد',
        'ريم عبدالله',
      ][i],
      jobTitle: 'أخصائي موارد بشرية',
      basicSalary: 12000,
      housingAllowance: 3000,
      transportAllowance: 1000,
      otherAllowance: 500.50,
      total: 16500.50,
    ),
  );
  @override
  Future<List<PayrollItem>> fetchPreparationItems() async => items;
  @override
  Future<String> createRun({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    creates++;
    return 'saved';
  }

  @override
  Future<List<PayrollItem>> fetchRunItems({required String runId}) async =>
      items;
  @override
  Future<void> submitToFinanceManager({required String runId}) async {
    sends++;
    if (failSubmit) throw StateError('Submit failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget app(
  PreparationRepo repo, {
  String lang = 'ar',
  ValueChanged<String>? onSubmitted,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: EmployeeTheme.from(AppTheme.light()),
  locale: Locale(lang),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: appLocalizationDelegates,
  home: Scaffold(
    body: PayrollPreparationView(
      repo: repo,
      onHistory: () {},
      onSubmitted: onSubmitted ?? (_) {},
    ),
  ),
);

void main() {
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1350.0]) {
      testWidgets(
        'Preparation $lang $width opens read-only preview and saves once',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 1200));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final repo = PreparationRepo();
          String? submitted;
          await tester.pumpWidget(
            app(repo, lang: lang, onSubmitted: (id) => submitted = id),
          );
          await tester.pumpAndSettle();
          expect(repo.creates, 0);
          expect(find.text('سارة أحمد'), findsOneWidget);
          expect(find.text('82,502.50'), findsOneWidget);
          expect(tester.takeException(), isNull);
          final save = find.byKey(const ValueKey('payroll-save'));
          await tester.ensureVisible(save);
          await tester.tap(save);
          await tester.pumpAndSettle();
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(repo.creates, 1);
          final send = find.byKey(const ValueKey('payroll-submit'));
          await tester.ensureVisible(send);
          await tester.tap(send);
          await tester.pumpAndSettle();
          expect(submitted, 'saved');
          expect(repo.creates, 1);
          expect(repo.sends, 1);
        },
      );
    }
  }
  testWidgets(
    'Failed submission retries the saved draft without duplicate creation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1350, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = PreparationRepo()..failSubmit = true;
      await tester.pumpWidget(app(repo));
      await tester.pumpAndSettle();
      final send = find.byKey(const ValueKey('payroll-submit'));
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(repo.creates, 1);
      repo.failSubmit = false;
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(repo.creates, 1);
      expect(repo.sends, 2);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Preparation visual preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_PAYROLL_PREPARATION')) return;
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
    await tester.binding.setSurfaceSize(const Size(1350, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: app(PreparationRepo())),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/hr_payroll_preparation_preview.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
