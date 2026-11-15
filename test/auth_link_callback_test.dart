import 'dart:async';
import 'package:erp_sys/core/auth/auth_link_callback.dart';
import 'package:erp_sys/core/auth/auth_notifier.dart';
import 'package:erp_sys/features/auth/view/auth_link_error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Expired callback is an error, not a recovery session or route', () {
    const hash =
        'error=access_denied&error_code=otp_expired&error_description=Email+link+is+invalid+or+has+expired';
    final callback = AuthLinkCallback.fromUri(
      Uri.parse('http://localhost:3000/#$hash'),
    );
    expect(callback.failed, true);
    expect(callback.expired, true);
    expect(callback.isRecovery, false);
    expect(authSafeHashPath(hash), '/');
  });
  test(
    'Dashboard tokens and PKCE codes are recognized without storing tokens',
    () {
      final callback = AuthLinkCallback.fromUri(
        Uri.parse(
          'https://example.test/#access_token=fixture&refresh_token=fixture&type=recovery',
        ),
      );
      expect(callback.implicit, true);
      expect(callback.isRecovery, true);
      expect(authSafeHashPath('access_token=fixture&type=recovery'), '/');
      expect(
        AuthLinkCallback.fromUri(
          Uri.parse('https://example.test/?code=fixture'),
        ).isCallback,
        true,
      );
      expect(
        AuthLinkCallback.fromUri(
          Uri.parse('https://example.test/?code=fixture'),
        ).implicit,
        false,
      );
    },
  );
  test(
    'Normal hash routes remain unchanged and malformed fragments do not crash',
    () {
      expect(authSafeHashPath('/my?tab=tasks'), '/my?tab=tasks');
      expect(
        AuthLinkCallback.fromUri(
          Uri.parse('https://example.test/#/my?tab=tasks'),
        ).isCallback,
        false,
      );
      expect(() => authSafeHashPath('error_description=%'), returnsNormally);
    },
  );
  test(
    'Expired callback can be dismissed even with an existing session',
    () async {
      final stream = StreamController<AuthState>(sync: true);
      final notifier = AuthNotifier(
        authChanges: stream.stream,
        sessionExists: () => true,
        initialUri: Uri.parse(
          'https://example.test/#error=access_denied&error_code=otp_expired',
        ),
      );
      expect(notifier.authLinkFailed, true);
      expect(notifier.isPasswordRecovery, false);
      notifier.dismissAuthLinkError();
      expect(notifier.authLinkFailed, false);
      notifier.dispose();
      await stream.close();
      AuthLinkStartup.callback = null;
    },
  );
  test(
    'Auth callback stream failures are handled and valid recovery clears failure',
    () async {
      final stream = StreamController<AuthState>(sync: true);
      final notifier = AuthNotifier(
        authChanges: stream.stream,
        sessionExists: () => false,
        initialUri: Uri.parse('https://example.test/#type=recovery'),
      );
      stream.addError(const AuthException('Fixture failure'));
      expect(notifier.authLinkFailed, true);
      stream.add(AuthState(AuthChangeEvent.passwordRecovery, null));
      expect(notifier.authLinkFailed, false);
      expect(notifier.isPasswordRecovery, true);
      notifier.dispose();
      await stream.close();
    },
  );
  for (final language in ['ar', 'en']) {
    testWidgets('Expired link shows a usable error screen in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var continued = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: AuthLinkErrorPage(
            expired: true,
            onContinue: () => continued = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(language == 'ar' ? 'انتهت صلاحيته' : 'has expired'),
        findsOneWidget,
      );
      await tester.tap(find.byType(FilledButton));
      expect(continued, true);
      expect(tester.takeException(), isNull);
    });
  }
}
