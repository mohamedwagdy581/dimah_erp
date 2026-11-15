import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/hr_alerts/domain/models/government_alert_item.dart';
import 'package:erp_sys/features/hr_alerts/view/widgets/government_alerts/government_alerts_table.dart';

void main() {
  for (final lang in ['ar', 'en']) {
    testWidgets(
      'Dragging bottom scrollbar reveals actions on small windows $lang',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(768, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final item = GovernmentAlertItem(
          id: 'scroll',
          title: 'Office lease',
          alertType: 'office_lease',
          startDate: DateTime(2025),
          endDate: DateTime(2026),
          daysLeft: -10,
        );
        String? renewed;
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(lang),
            theme: EmployeeTheme.from(AppTheme.light()),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GovernmentAlertsTable(
                items: [item],
                stateById: const {},
                onRenew: (i) => renewed = i.id,
                onEdit: (_) {},
                onSnooze: (_) {},
                onDelete: (_) {},
                onHandled: (_) {},
                onRestore: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final bar = find.byKey(
          const ValueKey('government-horizontal-scrollbar'),
        );
        final scroll = tester
            .widget<SingleChildScrollView>(
              find.byKey(const ValueKey('government-horizontal-scroll')),
            )
            .controller!;
        expect(scroll.position.maxScrollExtent, greaterThan(0));
        expect(tester.widget<Scrollbar>(bar).thumbVisibility, isTrue);
        final rect = tester.getRect(bar);
        final thumbWidth =
            rect.width *
            rect.width /
            (rect.width + scroll.position.maxScrollExtent);
        final x = lang == 'ar'
            ? rect.right - thumbWidth / 2
            : rect.left + thumbWidth / 2;
        final mouse = await tester.startGesture(
          Offset(x, rect.bottom - 6),
          kind: ui.PointerDeviceKind.mouse,
        );
        await mouse.moveBy(Offset(lang == 'ar' ? -500 : 500, 0));
        await mouse.up();
        await tester.pumpAndSettle();
        expect(scroll.offset, closeTo(scroll.position.maxScrollExtent, 1));
        final action = find.byKey(const ValueKey('government-renew-scroll'));
        expect(rect.contains(tester.getCenter(action)), isTrue);
        await tester.tap(action);
        expect(renewed, 'scroll');
        await tester.binding.setSurfaceSize(const Size(1800, 600));
        await tester.pumpAndSettle();
        expect(scroll.position.maxScrollExtent, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Government table fills resized viewport and actions follow follow-up',
    (tester) async {
      final item = GovernmentAlertItem(
        id: 'layout',
        title: 'Office lease',
        alertType: 'office_lease',
        startDate: DateTime(2025),
        endDate: DateTime(2026),
        daysLeft: -30,
      );
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final lang in ['ar', 'en']) {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(lang),
            theme: EmployeeTheme.from(AppTheme.light()),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GovernmentAlertsTable(
                items: [for (var i = 0; i < 30; i++) item],
                stateById: const {},
                onRenew: (_) {},
                onEdit: (_) {},
                onSnooze: (_) {},
                onDelete: (_) {},
                onHandled: (_) {},
                onRestore: (_) {},
              ),
            ),
          ),
        );
        for (final width in [320.0, 768.0, 1600.0, 2400.0]) {
          await tester.binding.setSurfaceSize(Size(width, 900));
          await tester.pumpAndSettle();
          final frame = tester.getSize(
            find.byKey(const ValueKey('government-table-frame')),
          );
          expect(frame.width, width);
          expect(frame.height, 900);
          final actions = tester
              .getCenter(find.text(lang == 'ar' ? 'الإجراءات' : 'Actions'))
              .dx;
          final followUp = tester
              .getCenter(find.text(lang == 'ar' ? 'المتابعة' : 'Follow-up'))
              .dx;
          expect(
            lang == 'ar' ? actions < followUp : actions > followUp,
            isTrue,
          );
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
  testWidgets('Government table preview', (tester) async {
    if (!const bool.fromEnvironment('EXPORT_GOVERNMENT_TABLE')) return;
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
    await tester.binding.setSurfaceSize(const Size(1000, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          theme: EmployeeTheme.from(AppTheme.light()),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GovernmentAlertsTable(
              items: [
                for (var i = 0; i < 3; i++)
                  GovernmentAlertItem(
                    id: '$i',
                    title: 'إيجار مكتب البساتين',
                    description:
                        'إيجار مكتب جدة - حي البساتين - شارع إسماعيل الجوهري',
                    alertType: 'office_lease',
                    startDate: DateTime(2025, 7, 1),
                    endDate: DateTime(2026, 7, 1),
                    daysLeft: -98,
                    fileUrl: 'https://example.com/contract.pdf',
                  ),
              ],
              stateById: const {},
              onRenew: (_) {},
              onEdit: (_) {},
              onSnooze: (_) {},
              onDelete: (_) {},
              onHandled: (_) {},
              onRestore: (_) {},
            ),
          ),
        ),
      ),
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
        'build/government_table_preview.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
  for (final lang in ['ar', 'en']) {
    testWidgets(
      'Government row actions are visible and keep complete details $lang',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final description = List.filled(
          15,
          'Full office address and contract details',
        ).join(' ');
        final item = GovernmentAlertItem(
          id: 'lease',
          title: 'Office lease',
          alertType: 'office_lease',
          description: description,
          startDate: DateTime(2025, 7, 1),
          endDate: DateTime(2026, 7, 1),
          daysLeft: -98,
        );
        final withFile = GovernmentAlertItem(
          id: 'subscription',
          title: 'Subscription',
          alertType: 'other',
          fileUrl: 'https://example.com/contract.pdf',
          startDate: DateTime(2026),
          endDate: DateTime(2027),
          daysLeft: 90,
        );
        String? renewed, edited, snoozed;
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(lang),
            theme: EmployeeTheme.from(AppTheme.light()),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GovernmentAlertsTable(
                items: [item, withFile],
                stateById: const {},
                onRenew: (i) => renewed = i.id,
                onEdit: (i) => edited = i.id,
                onSnooze: (i) => snoozed = i.id,
                onDelete: (_) {},
                onHandled: (_) {},
                onRestore: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.byKey(const ValueKey('government-renew-lease')),
        );
        await tester.tap(find.byKey(const ValueKey('government-renew-lease')));
        expect(renewed, 'lease');
        expect(
          find.text(lang == 'ar' ? 'عرض المرفق' : 'View attachment'),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('government-view-lease')),
        );
        await tester.tap(find.byKey(const ValueKey('government-view-lease')));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(description),
          ),
          findsOneWidget,
        );
        await tester.tap(
          find.widgetWithText(FilledButton, lang == 'ar' ? 'تعديل' : 'Edit'),
        );
        await tester.pumpAndSettle();
        expect(edited, 'lease');
        await tester.ensureVisible(
          find.byKey(const ValueKey('government-menu-lease')),
        );
        await tester.tap(find.byKey(const ValueKey('government-menu-lease')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(lang == 'ar' ? 'تأجيل 7 أيام' : 'Snooze 7 Days'),
        );
        await tester.pumpAndSettle();
        expect(snoozed, 'lease');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
