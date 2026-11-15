import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');
  static String get apiBaseUrl =>
      dotenv.env['DIMAH_API_URL']?.trim().isNotEmpty == true
      ? dotenv.env['DIMAH_API_URL']!.trim()
      : 'https://api.dimahmusic.com';

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('Missing $key in .env');
    }
    return value;
  }
}
