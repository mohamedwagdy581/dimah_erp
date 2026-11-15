import 'package:flutter/material.dart';
import 'employee_theme.dart';

/// Consistent controls and dialogs across the existing admin workspaces.
class AdminTheme {
  static ThemeData from(ThemeData base) {
    final theme = EmployeeTheme.from(base);
    const purple = Color(0xFF8659BB),
        ink = Color(0xFF21194E),
        border = Color(0xFFE5DDF2);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    return theme.copyWith(
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: ink,
          height: 1.6,
        ),
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: purple, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: shape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: purple,
          side: const BorderSide(color: border),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: shape,
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F1FA)),
        headingRowHeight: 54,
        dataRowMinHeight: 56,
        dataRowMaxHeight: 72,
        headingTextStyle: base.textTheme.labelLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w700,
        ),
        dataTextStyle: base.textTheme.bodyMedium?.copyWith(color: ink),
      ),
    );
  }
}
