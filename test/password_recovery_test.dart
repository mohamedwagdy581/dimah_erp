import 'dart:async';
import 'package:erp_sys/features/auth/data/repos/password_recovery_repo.dart';
import 'package:erp_sys/features/auth/view/password_recovery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecoveryFixture implements PasswordRecoveryRepo {
  int sends = 0, verifies = 0;
  String? email, token;
  bool failSend = false, failVerify = false;
  Completer<void>? pending;
  @override
  Future<void> sendCode(String value) async {
    sends++;
    email = value;
    if (failSend) throw StateError('SocketException');
    await pending?.future;
  }

  @override
  Future<void> verifyCode(String value, String code) async {
    verifies++;
    email = value;
    token = code;
    if (failVerify) throw const AuthException('Expired code');
  }
}

Future<void> mount(
  WidgetTester tester,
  RecoveryFixture repo, {
  String language = 'en',
  double width = 768,
  VoidCallback? onVerified,
}) async {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
  });
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: PasswordRecoveryPage(
        repo: repo,
        onVerified: onVerified,
        onCancel: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> send(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('recovery-email')),
    ' fixture@example.test ',
  );
  final submit = find.byKey(const Key('recovery-submit'));
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

void main() {
  test(
    'Recovery codes normalize Arabic and Persian digits with whitespace',
    () {
      expect(normalizeRecoveryCode(' ١٢٣ ۴۵۶ '), '123456');
    },
  );
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets('Recovery works inside application $language $width', (
        tester,
      ) async {
        final repo = RecoveryFixture();
        var verified = false;
        await mount(
          tester,
          repo,
          language: language,
          width: width,
          onVerified: () => verified = true,
        );
        await send(tester);
        expect(repo.sends, 1);
        expect(repo.email, 'fixture@example.test');
        await tester.enterText(
          find.byKey(const Key('recovery-code')),
          '١٢٣٤٥٦',
        );
        final button = find.byKey(const Key('recovery-submit'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(verified, isTrue);
        expect(repo.token, '123456');
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('Send failure preserves email and allows retry', (tester) async {
    final repo = RecoveryFixture()..failSend = true;
    await mount(tester, repo);
    await send(tester);
    expect(
      find.text(
        'Could not send the recovery email. Check your connection and retry.',
      ),
      findsOneWidget,
    );
    repo.failSend = false;
    await tester.tap(find.byKey(const Key('recovery-submit')));
    await tester.pumpAndSettle();
    expect(repo.sends, 2);
    expect(find.byKey(const Key('recovery-code')), findsOneWidget);
  });
  testWidgets(
    'Expired code keeps user on recovery page; invalid format never verifies',
    (tester) async {
      final repo = RecoveryFixture()..failVerify = true;
      var verified = false;
      await mount(tester, repo, onVerified: () => verified = true);
      await send(tester);
      await tester.enterText(find.byKey(const Key('recovery-code')), 'abc');
      final button = find.byKey(const Key('recovery-submit'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(repo.verifies, 0);
      await tester.enterText(find.byKey(const Key('recovery-code')), '123456');
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(verified, isFalse);
      expect(
        find.text(
          'The code is invalid or expired. Use the latest email or request a new code.',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets('Busy send cannot be duplicated; resend has cooldown', (
    tester,
  ) async {
    final repo = RecoveryFixture()..pending = Completer<void>();
    await mount(tester, repo);
    await tester.enterText(
      find.byKey(const Key('recovery-email')),
      'fixture@example.test',
    );
    final button = find.byKey(const Key('recovery-submit'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(repo.sends, 1);
    repo.pending!.complete();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Resend in 60 seconds'),
          )
          .onPressed,
      isNull,
    );
    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send a new code'));
    await tester.tap(find.text('Send a new code'));
    await tester.pumpAndSettle();
    expect(repo.sends, 2);
  });
}
