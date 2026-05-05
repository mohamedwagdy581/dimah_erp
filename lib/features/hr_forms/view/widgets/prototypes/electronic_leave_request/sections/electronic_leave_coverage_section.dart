import 'package:flutter/material.dart';

import '../../shared/electronic_form_theme.dart';
import '../../shared/electronic_section_card.dart';
import '../electronic_leave_request_form_controller.dart';
import '../widgets/electronic_leave_form_field.dart';
import '../widgets/electronic_leave_form_row.dart';

class ElectronicLeaveCoverageSection extends StatelessWidget {
  const ElectronicLeaveCoverageSection({
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
      title: isArabic ? 'التغطية أثناء الإجازة' : 'Coverage During Leave',
      child: Column(
        children: [
          ElectronicLeaveFormRow(
            children: [
              ElectronicLeaveFormField(
                controller: controller.replacement,
                label: isArabic ? 'الموظف البديل' : 'Replacement Employee',
                readOnly: readOnly,
              ),
              ElectronicLeaveFormField(
                controller: controller.replacementSignature,
                label: isArabic
                    ? 'توقيع الموظف البديل'
                    : 'Replacement Signature',
                readOnly: readOnly,
              ),
            ],
          ),
          const SizedBox(height: ElectronicFormDimensions.sectionSpacing),
          ElectronicLeaveFormRow(
            children: [
              ElectronicLeaveFormField(
                controller: controller.applicantSignature,
                label: isArabic ? 'توقيع مقدم الطلب' : 'Applicant Signature',
                readOnly: readOnly,
              ),
              ElectronicLeaveFormField(
                controller: controller.lineManagerSignature,
                label: isArabic
                    ? 'توقيع المدير المباشر'
                    : 'Line Manager Signature',
                readOnly: readOnly,
              ),
            ],
          ),
          const SizedBox(height: ElectronicFormDimensions.sectionSpacing),
          ElectronicLeaveFormRow(
            children: [
              ElectronicLeaveFormField(
                controller: controller.notes,
                label: isArabic ? 'ملاحظات إضافية' : 'Additional Notes',
                minLines: 2,
                readOnly: readOnly,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
