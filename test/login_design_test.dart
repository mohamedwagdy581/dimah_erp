import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/l10n/app_localization_delegates.dart';
import 'package:erp_sys/l10n/app_localizations.dart';
import 'package:erp_sys/features/auth/domain/repos/auth_repo.dart';
import 'package:erp_sys/features/auth/view/login_page.dart';

class Repo implements AuthRepo {
  int calls = 0;
  Object? error;
  Completer<void>? gate;
  String? email, password;
  @override
  Future<void> signIn({required String email, required String password}) async {
    calls++;
    this.email = email;
    this.password = password;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
  }

  @override
  Future<void> signOut() async {}
  @override
  Future<void> changePassword(String newPassword) async {}
  @override
  bool get isSignedIn => false;
}

Widget app(Repo repo, {String lang = 'ar', VoidCallback? success}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: appLocalizationDelegates,
      theme: AppTheme.light(),
      home: LoginPage(repo: repo, onLoggedIn: success ?? () {}),
    );
Finder field(String id) => find.byKey(ValueKey('login-$id'));
Future<void> submit(WidgetTester t) async {
  await t.ensureVisible(field('submit'));
  await t.pumpAndSettle();
  await t.tap(field('submit'));
  await t.pumpAndSettle();
}

Future<void> fill(WidgetTester t) async {
  await t.ensureVisible(field('email'));
  await t.enterText(field('email'), '  user@example.test  ');
  await t.enterText(field('password'), ' password with spaces ');
}

void main() {
  for (final lang in ['ar', 'en']) {
    for (final size in [
      const Size(320, 640),
      const Size(800, 480),
      const Size(1440, 900),
    ]) {
      testWidgets('Login $lang at $size retains fields after inline failure', (
        t,
      ) async {
        await t.binding.setSurfaceSize(size);
        addTearDown(() => t.binding.setSurfaceSize(null));
        final repo = Repo()..error = StateError('Invalid login credentials');
        await t.pumpWidget(app(repo, lang: lang));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        await fill(t);
        await submit(t);
        expect(repo.calls, 1);
        expect(repo.email, 'user@example.test');
        expect(repo.password, ' password with spaces ');
        expect(
          find.text(
            lang == 'ar'
                ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'
                : 'Email or password is incorrect.',
          ),
          findsOneWidget,
        );
        expect(
          t.widget<TextFormField>(field('password')).controller!.text,
          ' password with spaces ',
        );
        await t.ensureVisible(field('visibility'));
        await t.pumpAndSettle();
        await t.tap(field('visibility'));
        await t.pumpAndSettle();
        final editable = t.widget<EditableText>(
          find.descendant(
            of: field('password'),
            matching: find.byType(EditableText),
          ),
        );
        expect(editable.obscureText, false);
        expect(t.takeException(), isNull);
      });
    }
  }
  testWidgets('Empty and invalid fields never submit', (t) async {
    final repo = Repo();
    await t.pumpWidget(app(repo));
    await t.pumpAndSettle();
    await submit(t);
    expect(repo.calls, 0);
    await t.enterText(field('email'), 'invalid');
    await t.enterText(field('password'), 'pass');
    await submit(t);
    expect(repo.calls, 0);
  });
  testWidgets('Enter moves focus then signs in once and reports success', (
    t,
  ) async {
    final repo = Repo()..gate = Completer<void>();
    var successes = 0;
    await t.pumpWidget(app(repo, success: () => successes++));
    await t.pumpAndSettle();
    await t.enterText(field('email'), 'user@example.test');
    await t.testTextInput.receiveAction(TextInputAction.next);
    await t.pump();
    expect(
      t
          .widget<EditableText>(
            find.descendant(
              of: field('password'),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      true,
    );
    await t.enterText(field('password'), 'password');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
    expect(repo.calls, 1);
    expect(t.widget<TextButton>(field('submit')).onPressed, isNull);
    repo.gate!.complete();
    await t.pumpAndSettle();
    expect(successes, 1);
  });
  testWidgets('Connection failure is not reported as invalid credentials', (
    t,
  ) async {
    final repo = Repo()..error = const SocketException('offline');
    await t.pumpWidget(app(repo));
    await t.pumpAndSettle();
    await fill(t);
    await submit(t);
    expect(
      find.text('تعذّر تسجيل الدخول. تحقق من الاتصال وحاول مرة أخرى.'),
      findsOneWidget,
    );
    expect(find.textContaining('SocketException'), findsNothing);
    repo.error = null;
    await submit(t);
    expect(repo.calls, 2);
  });
  testWidgets('Visual login preview', (t) async {
    if (!const bool.fromEnvironment('EXPORT_LOGIN')) return;
    await t.runAsync(() async {
      for (final font in {
        'Roboto': 'C:/Windows/Fonts/segoeui.ttf',
        'serif': 'C:/Windows/Fonts/times.ttf',
        'MaterialIcons':
            'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(font.key)..addFont(
              Future.value(
                ByteData.sublistView(await File(font.value).readAsBytes()),
              ),
            ))
            .load();
      }
    });
    await t.binding.setSurfaceSize(const Size(1250, 760));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: app(Repo()..error = StateError('Invalid login credentials')),
      ),
    );
    await t.pumpAndSettle();
    await fill(t);
    await submit(t);
    await t.runAsync(() async {
      final picture =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      File(
        'build/login_preview.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  });
}
