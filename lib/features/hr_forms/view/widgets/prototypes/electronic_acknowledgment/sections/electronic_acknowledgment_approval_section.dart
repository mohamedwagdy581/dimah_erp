import 'package:flutter/material.dart';

import '../../shared/electronic_section_card.dart';
import '../electronic_acknowledgment_form_controller.dart';
import '../widgets/electronic_acknowledgment_form_field.dart';
import '../widgets/electronic_acknowledgment_form_row.dart';

class ElectronicAcknowledgmentApprovalSection extends StatelessWidget {
  const ElectronicAcknowledgmentApprovalSection({
    super.key,
    required this.controller,
    required this.isArabic,
    required this.readOnly,
  });

  final ElectronicAcknowledgmentFormController controller;
  final bool isArabic;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return ElectronicSectionCard(
      title: isArabic ? 'الاعتماد' : 'Approval',
      hint: readOnly ? null : (isArabic ? 'حقل توقيع' : 'Signature Area'),
      child: ElectronicAcknowledgmentFormRow(
        children: [
          ElectronicAcknowledgmentFormField(
            controller: controller.signature,
            label: isArabic ? 'توقيع الموظف' : 'Employee Signature',
            minLines: 3,
            readOnly: readOnly,
          ),
        ],
      ),
    );
  }
}
