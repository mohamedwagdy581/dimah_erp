import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/employees/domain/models/expiry_alert.dart';
import 'package:erp_sys/features/hr_alerts/data/repos/hr_alerts_repo.dart';
import 'package:erp_sys/features/hr_alerts/domain/models/hr_alerts_data.dart';
import 'package:erp_sys/features/hr_alerts/domain/models/hr_alert_state_info.dart';
import 'package:erp_sys/features/hr_alerts/view/pages/hr_alerts_page.dart';

class Alerts implements HrAlertsRepo {
  ExpiryAlertSettings settings = const ExpiryAlertSettings(
    contractAlertDays: 30,
    residencyAlertDays: 30,
    insuranceAlertDays: 30,
    documentsAlertDays: 30,
  );
  int saves = 0;
  bool fail = false;
  final items = List.generate(
    6,
    (i) => ExpiryAlertItem(
      employeeId: '$i',
      employeeName: [
        'أحمد محمد السالم',
        'سارة خالد العتيبي',
        'محمد عبدالله القحطاني',
        'نورة إبراهيم المطيري',
        'خالد علي الزهراني',
        'Handled employee',
      ][i],
      type: [
        'document:id_card',
        'residency',
        'document:passport',
        'contract',
        'insurance',
        'document:id_card',
      ][i],
      expiryDate: DateTime(
        2026,
        10,
        7,
      ).add(Duration(days: [-2, 20, 26, -1, 30, 15][i])),
      daysLeft: [-2, 20, 26, -1, 30, 15][i],
    ),
  );
  @override
  Future<HrAlertsData> load({bool includeHidden = false}) async {
    expect(includeHidden, isTrue);
    return HrAlertsData(
      settings: settings,
      items: items,
      employeeStates: {
        employeeAlertKey(items.last): HrAlertStateInfo(
          resolvedAt: DateTime(2026, 10, 1),
        ),
      },
    );
  }

  @override
  Future<void> saveSettings(ExpiryAlertSettings value) async {
    if (fail) throw StateError('failure');
    saves++;
    settings = value;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget app(Alerts repo, {String lang = 'ar', GoRouter? router}) =>
    router == null
    ? MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: EmployeeTheme.from(AppTheme.light()),
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: HrAlertsPage(repo: repo)),
      )
    : MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: EmployeeTheme.from(AppTheme.light()),
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      );
void main() {
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1350.0]) {
      testWidgets('Expiry alerts $lang $width render and save validation', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repo = Alerts();
        await tester.pumpWidget(app(repo, lang: lang));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Handled employee'), findsNothing);
        final days = find.byKey(const ValueKey('alert-days'));
        await tester.ensureVisible(days);
        await tester.enterText(days, '0');
        final save = find.byKey(const ValueKey('save-alert-settings'));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(repo.saves, 0);
        await tester.enterText(days, '45');
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(repo.saves, 1);
        expect(repo.settings.documentsAlertDays, 45);
        expect(repo.settings.contractAlertDays, 45);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'Filters and follow-up preserve hidden alerts and expired boundary',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1350, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(Alerts(), lang: 'en'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All follow-ups'));
      await tester.pumpAndSettle();
      expect(find.text('Handled employee'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('alert-expiry-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expired').last);
      await tester.pumpAndSettle();
      expect(find.text('سارة خالد العتيبي'), findsNothing);
      expect(find.text('أحمد محمد السالم'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Passport'));
      await tester.pumpAndSettle();
      expect(find.text('أحمد محمد السالم'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Failed settings save retains entered value for retry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1350, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = Alerts()..fail = true;
    await tester.pumpWidget(app(repo, lang: 'en'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('alert-days')), '55');
    await tester.tap(find.byKey(const ValueKey('save-alert-settings')));
    await tester.pumpAndSettle();
    expect(repo.saves, 0);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('alert-days')))
          .controller!
          .text,
      '55',
    );
    repo.fail = false;
    await tester.tap(find.byKey(const ValueKey('save-alert-settings')));
    await tester.pumpAndSettle();
    expect(repo.saves, 1);
  });
  testWidgets('Renewal opens employee document form with renewal dates', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1350, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = Alerts();
    final router = GoRouter(
      initialLocation: '/hr-alerts',
      routes: [
        GoRoute(
          path: '/hr-alerts',
          builder: (_, state) => Scaffold(body: HrAlertsPage(repo: repo)),
        ),
        GoRoute(
          path: '/employee-docs',
          builder: (_, state) => Scaffold(body: Text(state.uri.toString())),
        ),
        GoRoute(
          path: '/employees/:id',
          builder: (_, state) => Scaffold(body: Text(state.uri.toString())),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(app(repo, lang: 'en', router: router));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Renew document').first,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Renew document').first);
    await tester.pumpAndSettle();
    final destination = find.byWidgetPredicate(
      (w) => w is Text && (w.data?.startsWith('/employee-docs?') ?? false),
    );
    expect(destination, findsOneWidget);
    final uri = Uri.parse(tester.widget<Text>(destination).data!);
    expect(uri.path, '/employee-docs');
    expect(uri.queryParameters['docType'], 'id_card');
    expect(uri.queryParameters['employeeId'], '0');
    expect(uri.queryParameters['openCreate'], '1');
    expect(uri.queryParameters['oldExpiresAt'], isNotNull);
  });
  testWidgets('Expiry visual preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_HR_EXPIRY')) return;
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
    await tester.binding.setSurfaceSize(const Size(1350, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: app(Alerts())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/hr_expiry_alerts_preview.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
