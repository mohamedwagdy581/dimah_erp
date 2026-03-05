import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings_state.dart';

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit() : super(AppSettingsState.initial) {
    load();
  }

  static const _kThemeMode = 'app_theme_mode';
  static const _kLocale = 'app_locale';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeRaw = prefs.getString(_kThemeMode);
    final localeRaw = prefs.getString(_kLocale);

    ThemeMode mode = ThemeMode.dark;
    if (themeRaw == 'light') mode = ThemeMode.light;
    if (themeRaw == 'system') mode = ThemeMode.system;

    final locale = localeRaw == 'ar' ? const Locale('ar') : const Locale('en');
    emit(state.copyWith(themeMode: mode, locale: locale));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_kThemeMode, raw);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> toggleTheme() async {
    final next = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(next);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, locale.languageCode);
    emit(state.copyWith(locale: locale));
  }

  Future<void> toggleLanguage() async {
    final next = state.locale.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    await setLocale(next);
  }
}
