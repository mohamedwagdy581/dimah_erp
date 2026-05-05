import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/my_app.dart';
import 'core/di/app_di.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrap();
  runApp(const MyApp());
}

Future<void> _bootstrap() async {
  await dotenv.load(fileName: ".env");

  if (kDebugMode) {
    print('Supabase URL: ${Env.supabaseUrl}');
    print('Supabase Anon Key: ${Env.supabaseAnonKey}');
  }

  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);

  AppDI.init();
}
