import 'package:flutter/material.dart';

import '../../../../../../core/ui/app_colors.dart';
import '../../../../../../core/ui/app_radius.dart';
import '../../../../../../core/ui/app_spacing.dart';

abstract class ElectronicFormColors {
  // Use global app colors instead of duplicating
  static const Color cardBackground = AppColors.surfaceLight;
  static const Color cardBorder = AppColors.hrInputBorder;
  static const Color headingText = AppColors.hrPrimary;
  static const Color subtitleText = AppColors.hrText;
  static const Color headerSurface = AppColors.hrHeaderBg;
  static const Color headerAccent = AppColors.hrAccent;
  static const Color footerSurface = AppColors.hrFooterBg;
  static const Color footerAccent = AppColors.hrAccent;
  static const Color footerShadowA = AppColors.hrPrimaryLight;
  static const Color footerShadowB = AppColors.hrPrimary;
  static const Color sectionBorder = AppColors.hrInputBorder;
  static const Color sectionHeader = AppColors.hrSectionHeader;
  static const Color sectionHintText = Color(0xFFE4F2EE);
  static const Color inputBorder = AppColors.hrInputBorder;
  static const Color inputBackground = AppColors.hrInputBg;
  static const Color inputBackgroundSecondary = AppColors.hrInputBgSecondary;
  static const Color inputLabelDark = Color(0xFF486673);
  static const Color inputLabel = AppColors.hrLabelText;
  static const Color accentIcon = AppColors.hrPrimary;
}

abstract class ElectronicFormTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: ElectronicFormColors.headingText,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    color: ElectronicFormColors.subtitleText,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle sectionHint = TextStyle(
    color: ElectronicFormColors.sectionHintText,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle sectionLabel = TextStyle(fontWeight: FontWeight.w700);

  static const TextStyle inputLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: ElectronicFormColors.inputLabel,
  );
}

abstract class ElectronicFormDimensions {
  // Card dimensions
  static const double cardWidth = 980.0;
  static const double cardHorizontalPadding = AppSpacing.pageHorizontal;
  static const double cardVerticalPadding = AppSpacing.pageVertical;
  static const double cardRadius = AppRadius.large;
  static const double cardShadowBlur = 26.0;
  static const double cardShadowOffset = 12.0;

  // Header dimensions
  static const double headerLogoSize = 104.0;
  static const double headerLogoPadding = AppSpacing.s12;
  static const double headerWidth = 320.0;
  static const double headerHeight = 200.0;
  static const double headerRadius = AppRadius.r12;
  static const double headerAccentWidth = 200.0;
  static const double headerAccentHeight = 30.0;
  static const double headerAccentOffset = 22.0;

  // Footer dimensions
  static const double footerHeight = 140.0;
  static const double footerShape1Width = 600.0;
  static const double footerShape2Width = 800.0;
  static const double footerShapeRadius = AppRadius.r12;
  static const double footerShadowBlur = 18.0;
  static const double footerShadowOffset = 8.0;

  // Section dimensions
  static const double sectionRadius = AppRadius.large;
  static const double sectionHeaderRadius = 21.0;
  static const double sectionSpacing = AppSpacing.sectionMargin;
  static const double sectionPadding = AppSpacing.sectionPadding;
  static const double inputBorderRadius = AppRadius.input;
  static const double inputPaddingHorizontal = AppSpacing.s14;
  static const double inputPaddingVertical = AppSpacing.s8;
  static const double inputFieldSpacing = AppSpacing.s4;
  static const double rowSpacing = AppSpacing.rowSpacing;
  static const double dropdownWidth = 320.0;
  static const double iconSize = 18.0;
  static const double actionSpacing = AppSpacing.s10;
  static const double textSpacing = AppSpacing.s6;
  static const double headerTopSpacing = 72.0;
}

abstract class ElectronicFormDecorations {
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: ElectronicFormColors.cardBackground,
    borderRadius: BorderRadius.all(
      Radius.circular(ElectronicFormDimensions.cardRadius),
    ),
    boxShadow: [
      const BoxShadow(
        color: Color(0x12000000),
        blurRadius: ElectronicFormDimensions.cardShadowBlur,
        offset: Offset(0, ElectronicFormDimensions.cardShadowOffset),
      ),
    ],
    border: Border.all(color: ElectronicFormColors.cardBorder),
  );

  static final BoxDecoration sectionDecoration = BoxDecoration(
    color: ElectronicFormColors.cardBackground,
    borderRadius: BorderRadius.all(
      Radius.circular(ElectronicFormDimensions.sectionRadius),
    ),
    border: Border.all(color: ElectronicFormColors.sectionBorder),
  );

  static const BoxDecoration sectionHeaderDecoration = BoxDecoration(
    color: ElectronicFormColors.sectionHeader,
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(ElectronicFormDimensions.sectionHeaderRadius),
    ),
  );
}
