import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/my_app.dart';
import 'core/di/app_di.dart';
import 'core/config/env.dart';
import 'core/auth/auth_link_callback.dart';
import 'core/auth/auth_url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureAuthUrlStrategy();
  await _bootstrap();
  runApp(const MyApp());
}

Future<void> _bootstrap() async {
  final initialUri = Uri.base;
  final callback = AuthLinkCallback.fromUri(initialUri);
  AuthLinkStartup.callback = callback;
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      detectSessionInUri: !kIsWeb,
      authFlowType: kIsWeb && callback.implicit
          ? AuthFlowType.implicit
          : AuthFlowType.pkce,
    ),
  );
  if (kIsWeb && callback.isCallback && !callback.failed) {
    try {
      final response = await Supabase.instance.client.auth.getSessionFromUrl(
        initialUri,
      );
      AuthLinkStartup.callback = AuthLinkCallback(
        isCallback: true,
        implicit: callback.implicit,
        isRecovery: callback.isRecovery || response.redirectType == 'recovery',
      );
    } on AuthException catch (error) {
      AuthLinkStartup.callback = AuthLinkCallback(
        isCallback: true,
        failed: true,
        expired:
            error.code == 'otp_expired' || error.statusCode == 'otp_expired',
      );
      // The Column is the main one i always use to show the Design
    } catch (_) {
      AuthLinkStartup.callback = const AuthLinkCallback(
        isCallback: true,
        failed: true,
      );
    }
  }

  AppDI.init();
}
