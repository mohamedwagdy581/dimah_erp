import 'package:material_ui/material_ui.dart';

/// Scoped to the ordinary employee shell; other roles retain their theme.
class EmployeeTheme {
  static const primary = Color(0xFF9B74BF);
  static const dark = Color(0xFF9870BD);
  static const light = Color(0xFFA07BC2);

  static ThemeData from(ThemeData base) {
    final isDark = base.brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: base.brightness,
    ).copyWith(primary: primary, onPrimary: Colors.white);
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? base.scaffoldBackgroundColor
          : const Color(0xFFFAFAFC),
      cardTheme: CardThemeData(
        color: isDark ? scheme.surface : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .35)),
        ),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
