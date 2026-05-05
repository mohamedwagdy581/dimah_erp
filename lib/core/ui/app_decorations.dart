import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';

/// Shared decorations and styles for consistent UI across the app
class AppDecorations {
  // Card decorations
  static final cardDecoration = BoxDecoration(
    color: AppColors.surfaceLight,
    borderRadius: BorderRadius.circular(AppRadius.card),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowLight,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static final cardDecorationBordered = BoxDecoration(
    color: AppColors.surfaceLight,
    borderRadius: BorderRadius.circular(AppRadius.card),
    border: Border.all(color: AppColors.borderLight),
  );

  // Input field decorations
  static final inputDecoration = BoxDecoration(
    color: AppColors.hrInputBg,
    borderRadius: BorderRadius.circular(AppRadius.input),
    border: Border.all(color: AppColors.hrInputBorder),
  );

  static final inputDecorationSecondary = BoxDecoration(
    color: AppColors.hrInputBgSecondary,
    borderRadius: BorderRadius.circular(AppRadius.input),
    border: Border.all(color: AppColors.hrInputBorder),
  );

  // Section decorations
  static final sectionDecoration = BoxDecoration(
    color: AppColors.surfaceLight,
    borderRadius: BorderRadius.circular(AppRadius.card),
    border: Border.all(color: AppColors.hrInputBorder),
  );

  static final sectionHeaderDecoration = BoxDecoration(
    color: AppColors.hrSectionHeader,
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
  );

  // Chip decorations
  static final chipDecorationGreen = BoxDecoration(
    color: AppColors.chipBgGreen,
    borderRadius: BorderRadius.circular(AppRadius.chip),
    border: Border.all(color: AppColors.chipFgGreen.withOpacity(0.18)),
  );

  static final chipDecorationBlue = BoxDecoration(
    color: AppColors.chipBgBlue,
    borderRadius: BorderRadius.circular(AppRadius.chip),
    border: Border.all(color: AppColors.chipFgBlue.withOpacity(0.18)),
  );

  static final chipDecorationBrown = BoxDecoration(
    color: AppColors.chipBgBrown,
    borderRadius: BorderRadius.circular(AppRadius.chip),
    border: Border.all(color: AppColors.chipFgBrown.withOpacity(0.18)),
  );

  // Button decorations
  static final buttonDecoration = BoxDecoration(
    color: AppColors.brand,
    borderRadius: BorderRadius.circular(AppRadius.button),
  );

  static final buttonDecorationOutlined = BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.button),
    border: Border.all(color: AppColors.brand),
  );

  // Dialog decoration
  static final dialogDecoration = BoxDecoration(
    color: AppColors.surfaceLight,
    borderRadius: BorderRadius.circular(AppRadius.dialog),
  );
}
