import 'dart:io';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:erp_sys/core/ui/app_search_field.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';

Widget app(Widget child, {String lang = 'ar'}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  locale: Locale(lang),
  localizationsDelegates: appLocalizationDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  test('Connection, access denial and unknown failures are distinguished', () {
    expect(
      classifyDataFailure(const SocketException('unreachable')),
      DataFailureKind.connection,
    );
    expect(
      classifyDataFailure('ClientException: Failed to fetch'),
      DataFailureKind.connection,
    );
    expect(
      classifyDataFailure('PostgrestException(code: 42501, permission denied)'),
      DataFailureKind.forbidden,
    );
    expect(classifyDataFailure('statusCode: 403'), DataFailureKind.forbidden);
    expect(
      classifyDataFailure('database schema missing'),
      DataFailureKind.unknown,
    );
  });
  for (final lang in ['ar', 'en']) {
    for (final size in [
      const Size(320, 180),
      const Size(760, 520),
      const Size(1440, 800),
    ]) {
      testWidgets(
        'Every state fits $size in $lang and actions remain reachable',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          for (final state in <Widget>[
            const AppLoadingState(),
            const AppEmptyState(),
            AppEmptyState(filtered: true, onClear: () {}),
            AppFailureState(
              error: const SocketException('secret host'),
              onRetry: () {},
            ),
            AppFailureState(error: 'private SQL details', onRetry: () {}),
            AppAccessDeniedState(onHome: () {}),
          ]) {
            await tester.pumpWidget(app(state, lang: lang));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.textContaining('secret host'), findsNothing);
            expect(find.textContaining('private SQL'), findsNothing);
            final action = find.byWidgetPredicate(
              (w) => w is FilledButton || w is OutlinedButton,
            );
            if (action.evaluate().isNotEmpty) {
              await tester.ensureVisible(action);
              await tester.tap(action);
              expect(tester.takeException(), isNull);
            }
          }
        },
      );
    }
  }
  testWidgets('Loading and failed requests never show an empty data result', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const AppDataRegion(loading: true, child: AppEmptyState())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppLoadingState), findsOneWidget);
    expect(find.byType(AppEmptyState), findsNothing);
    var retries = 0;
    await tester.pumpWidget(
      app(
        AppDataRegion(
          error: 'unexpected error',
          onRetry: () => retries++,
          child: const AppEmptyState(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppEmptyState), findsNothing);
    await tester.tap(find.text('إعادة المحاولة'));
    expect(retries, 1);
    await tester.pumpWidget(app(const AppDataRegion(child: Text('records'))));
    await tester.pumpAndSettle();
    expect(find.text('records'), findsOneWidget);
  });
  testWidgets(
    'Filtered empty state clears filters; access denial returns home',
    (tester) async {
      var clears = 0, homes = 0;
      await tester.pumpWidget(
        app(AppEmptyState(filtered: true, onClear: () => clears++)),
      );
      await tester.pumpAndSettle();
      expect(find.text('لا توجد نتائج مطابقة'), findsOneWidget);
      await tester.tap(find.text('مسح الفلاتر'));
      expect(clears, 1);
      await tester.pumpWidget(app(AppAccessDeniedState(onHome: () => homes++)));
      await tester.pumpAndSettle();
      expect(find.text('إعادة المحاولة'), findsNothing);
      await tester.tap(find.text('العودة للرئيسية'));
      expect(homes, 1);
    },
  );
  testWidgets('Clearing filters also clears the visible search field', (
    tester,
  ) async {
    var value = 'old query';
    await tester.pumpWidget(
      app(AppSearchField(value: value, onChanged: (text) => value = text)),
    );
    expect(find.text('old query'), findsOneWidget);
    value = '';
    await tester.pumpWidget(
      app(AppSearchField(value: value, onChanged: (text) => value = text)),
    );
    expect(find.text('old query'), findsNothing);
    await tester.enterText(find.byType(TextField), 'new query');
    expect(value, 'new query');
  });
  testWidgets('Visual preview of shared states', (tester) async {
    if (!const bool.fromEnvironment('CAPTURE_DATA_STATES')) return;
    await tester.runAsync(() async {
      await (FontLoader('Roboto')..addFont(
            Future.value(
              ByteData.sublistView(
                await File(
                  'assets/fonts/DINNextLTArabic-Regular-2.ttf',
                ).readAsBytes(),
              ),
            ),
          ))
          .load();
      await (FontLoader('MaterialIcons')..addFont(
            Future.value(
              ByteData.sublistView(
                await File(
                  'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
                ).readAsBytes(),
              ),
            ),
          ))
          .load();
    });
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      app(
        RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: Colors.white,
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              children: [
                const AppLoadingState(),
                const AppEmptyState(),
                AppEmptyState(filtered: true, onClear: () {}),
                AppFailureState(
                  error: const SocketException('offline'),
                  onRetry: () {},
                ),
                AppFailureState(error: 'fetch error', onRetry: () {}),
                AppAccessDeniedState(onHome: () {}),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/data_states_preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  });
}
