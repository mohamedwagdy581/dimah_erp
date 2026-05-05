import 'package:flutter/material.dart';

import '../../shared/electronic_section_card.dart';
import '../widgets/electronic_acknowledgment_info_chip.dart';

class ElectronicAcknowledgmentSummarySection extends StatelessWidget {
  const ElectronicAcknowledgmentSummarySection({
    super.key,
    required this.isArabic,
  });

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return ElectronicSectionCard(
      title: isArabic ? 'ملخص سريع' : 'Quick Summary',
      hint: isArabic ? 'واجهة عرض' : 'Preview Surface',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ElectronicAcknowledgmentInfoChip(
            label: isArabic ? 'سري / داخلي' : 'Confidential / Internal',
            bg: const Color(0xFFEBF7F2),
            fg: const Color(0xFF2F7F66),
          ),
          ElectronicAcknowledgmentInfoChip(
            label: isArabic ? 'اعتماد موظف' : 'Employee Acknowledgment',
            bg: const Color(0xFFF0F8FB),
            fg: const Color(0xFF2E6E86),
          ),
          ElectronicAcknowledgmentInfoChip(
            label: isArabic ? 'نسخة للعميل' : 'Client Review Copy',
            bg: const Color(0xFFF8F4EA),
            fg: const Color(0xFF8B6A2D),
          ),
        ],
      ),
    );
  }
}
