import 'package:flutter/material.dart';

class HrFormTemplateDef {
  const HrFormTemplateDef({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.subtitleEn,
    required this.subtitleAr,
    required this.icon,
    required this.color,
  });

  final String id;
  final String titleEn;
  final String titleAr;
  final String subtitleEn;
  final String subtitleAr;
  final IconData icon;
  final Color color;

  String title(bool isArabic) => isArabic ? titleAr : titleEn;
  String subtitle(bool isArabic) => isArabic ? subtitleAr : subtitleEn;
}

const acknowledgmentPrototypeTemplateId = 'acknowledgment-prototype';
const leavePrototypeTemplateId = 'leave-application-prototype';

const hrFormTemplates = <HrFormTemplateDef>[
  HrFormTemplateDef(
    id: acknowledgmentPrototypeTemplateId,
    titleEn: 'Electronic Acknowledgment',
    titleAr: 'إقرار إلكتروني',
    subtitleEn: 'Official electronic acknowledgment template for employees',
    subtitleAr: 'نموذج إقرار إلكتروني رسمي للموظفين',
    icon: Icons.fact_check_outlined,
    color: Color(0xFF3B8D72),
  ),
  HrFormTemplateDef(
    id: leavePrototypeTemplateId,
    titleEn: 'Electronic Leave Request',
    titleAr: 'طلب إجازة إلكتروني',
    subtitleEn: 'Official electronic leave request form for employees',
    subtitleAr: 'نموذج طلب إجازة إلكتروني رسمي للموظفين',
    icon: Icons.assignment_turned_in_outlined,
    color: Color(0xFF2D7E9D),
  ),
];

HrFormTemplateDef? findHrFormTemplate(String id) {
  for (final item in hrFormTemplates) {
    if (item.id == id) return item;
  }
  return null;
}
