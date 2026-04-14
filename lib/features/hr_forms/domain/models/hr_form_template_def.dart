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

const emailRequestTemplateId = 'email-request';
const acknowledgmentTemplateId = 'acknowledgment-undertaking';
const leaveApplicationTemplateId = 'leave-application';
const acknowledgmentPrototypeTemplateId = 'acknowledgment-prototype';
const leavePrototypeTemplateId = 'leave-application-prototype';

const hrFormTemplates = <HrFormTemplateDef>[
  HrFormTemplateDef(
    id: emailRequestTemplateId,
    titleEn: 'Email Request',
    titleAr: 'طلب بريد إلكتروني',
    subtitleEn: 'Official employee email registration form',
    subtitleAr: 'نموذج رسمي لطلب إنشاء بريد إلكتروني للموظف',
    icon: Icons.alternate_email_outlined,
    color: Color(0xFF2D8C82),
  ),
  HrFormTemplateDef(
    id: acknowledgmentTemplateId,
    titleEn: 'Acknowledgment & Undertaking',
    titleAr: 'إقرار وتعهد',
    subtitleEn: 'Official acknowledgment template for employees',
    subtitleAr: 'نموذج إقرار وتعهد رسمي للموظفين',
    icon: Icons.assignment_outlined,
    color: Color(0xFF7A5C3E),
  ),
  HrFormTemplateDef(
    id: leaveApplicationTemplateId,
    titleEn: 'Leave Application',
    titleAr: 'طلب إجازة',
    subtitleEn: 'Official leave request form for employees',
    subtitleAr: 'نموذج رسمي لطلب الإجازة للموظفين',
    icon: Icons.event_note_outlined,
    color: Color(0xFF3568A8),
  ),
  HrFormTemplateDef(
    id: acknowledgmentPrototypeTemplateId,
    titleEn: 'Prototype Acknowledgment',
    titleAr: 'تجريبي - إقرار إلكتروني',
    subtitleEn: 'Experimental electronic acknowledgment layout for client review',
    subtitleAr: 'نسخة إلكترونية تجريبية للإقرار لمراجعة العميل',
    icon: Icons.fact_check_outlined,
    color: Color(0xFF3B8D72),
  ),
  HrFormTemplateDef(
    id: leavePrototypeTemplateId,
    titleEn: 'Prototype Leave Request',
    titleAr: 'تجريبي - طلب إجازة إلكتروني',
    subtitleEn: 'Experimental electronic leave request layout for client review',
    subtitleAr: 'نسخة إلكترونية تجريبية لطلب الإجازة لمراجعة العميل',
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
