import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/core/routing/app_routes.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/shell/domain/nav_menu.dart';
import 'package:erp_sys/features/shell/view/sections/sidebar_section.dart';
import 'package:erp_sys/features/shell/view/utils/shell_title_resolver.dart';

void main() {
  for (final language in ['ar', 'en']) {
    testWidgets(
      'HR approvals has correct title and purple sidebar in $language',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final router = GoRouter(
          initialLocation: AppRoutes.approvals,
          routes: [
            GoRoute(
              path: AppRoutes.approvals,
              builder: (context, state) => Scaffold(
                body: Row(
                  children: [
                    Expanded(
                      child: Text(
                        resolveShellTitle(context, role: 'hr'),
                        key: const ValueKey('page-title'),
                      ),
                    ),
                    SidebarSection(
                      isCollapsed: false,
                      onToggle: () {},
                      role: 'hr',
                      email: 'hr@example.test',
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: appLocalizationDelegates,
            theme: EmployeeTheme.from(ThemeData.light()),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          NavMenu.forRole('hr').any((item) => item.path == AppRoutes.approvals),
          true,
        );
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('page-title'))).data,
          language == 'ar' ? 'الموافقات' : 'Approvals',
        );
        expect(find.text('DIMAH'), findsOneWidget);
        final boxes = tester.widgetList<Container>(
          find.descendant(
            of: find.byType(SidebarSection),
            matching: find.byType(Container),
          ),
        );
        expect(
          boxes.any(
            (box) =>
                box.decoration is BoxDecoration &&
                (box.decoration as BoxDecoration).gradient != null,
          ),
          true,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
