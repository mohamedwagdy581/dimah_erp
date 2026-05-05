import 'package:flutter/material.dart';

import '../../shared/electronic_form_theme.dart';
import '../../shared/electronic_section_card.dart';
import '../electronic_leave_request_form_controller.dart';
import '../widgets/electronic_leave_form_field.dart';
import '../widgets/electronic_leave_form_row.dart';

class ElectronicLeaveHrUseSection extends StatelessWidget {
  const ElectronicLeaveHrUseSection({
    super.key,
    required this.controller,
    required this.isArabic,
    required this.readOnly,
  });

  final ElectronicLeaveRequestFormController controller;
  final bool isArabic;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return ElectronicSectionCard(
      title: isArabic
          ? 'خاص لاستخدام الموارد البشرية'
          : 'Used For HR Purposes Only',
      child: Column(
        children: [
          ElectronicLeaveFormRow(
            children: [
              ElectronicLeaveFormField(
                controller: controller.joiningDate,
                label: isArabic ? 'تاريخ بداية الخدمة' : 'Joining Date',
                readOnly: readOnly,
              ),
              ElectronicLeaveFormField(
                controller: controller.previousBalance,
                label: isArabic ? 'الرصيد السابق' : 'Previous Balance',
                readOnly: readOnly,
              ),
              ElectronicLeaveFormField(
                controller: controller.newBalance,
                label: isArabic ? 'الرصيد الجديد' : 'New Balance',
                readOnly: readOnly,
              ),
            ],
          ),
          const SizedBox(height: ElectronicFormDimensions.sectionSpacing),
          ElectronicLeaveFormRow(
            children: [
              ElectronicLeaveFormField(
                controller: controller.hrManagerSignature,
                label: isArabic
                    ? 'توقيع مدير الموارد البشرية'
                    : 'HR Manager Signature',
                readOnly: readOnly,
              ),
              ElectronicLeaveFormField(
                controller: controller.departmentManagerSignature,
                label: isArabic
                    ? 'توقيع مدير الإدارة'
                    : 'Department Manager Signature',
                readOnly: readOnly,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
