import 'package:flutter/material.dart';

import '../../shared/electronic_form_theme.dart';
import '../../shared/electronic_section_card.dart';
import '../electronic_acknowledgment_form_controller.dart';
import '../widgets/electronic_acknowledgment_form_field.dart';
import '../widgets/electronic_acknowledgment_form_row.dart';

class ElectronicAcknowledgmentEmployeeInfoSection extends StatelessWidget {
  const ElectronicAcknowledgmentEmployeeInfoSection({
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
      title: isArabic ? 'بيانات الموظف' : 'Employee Information',
      hint: readOnly ? null : (isArabic ? 'تجريبي' : 'Prototype'),
      child: Column(
        children: [
          ElectronicAcknowledgmentFormRow(
            children: [
              ElectronicAcknowledgmentFormField(
                controller: controller.employeeName,
                label: isArabic ? 'اسم الموظف' : 'Employee Name',
                readOnly: readOnly,
              ),
              ElectronicAcknowledgmentFormField(
                controller: controller.employeeId,
                label: isArabic ? 'رقم الهوية / الإقامة' : 'ID / Iqama Number',
                readOnly: readOnly,
              ),
            ],
          ),
          const SizedBox(height: ElectronicFormDimensions.sectionSpacing),
          ElectronicAcknowledgmentFormRow(
            children: [
              ElectronicAcknowledgmentFormField(
                controller: controller.department,
                label: isArabic ? 'القسم' : 'Department',
                readOnly: readOnly,
              ),
              ElectronicAcknowledgmentFormField(
                controller: controller.role,
                label: isArabic ? 'المسمى الوظيفي' : 'Job Title',
                readOnly: readOnly,
              ),
            ],
          ),
          const SizedBox(height: ElectronicFormDimensions.sectionSpacing),
          ElectronicAcknowledgmentFormRow(
            children: [
              ElectronicAcknowledgmentFormField(
                controller: controller.mobile,
                label: isArabic ? 'رقم الجوال' : 'Mobile Number',
                readOnly: readOnly,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
