import 'package:flutter/material.dart';

import '../../shared/electronic_form_theme.dart';
import '../../shared/electronic_section_card.dart';
import '../electronic_leave_request_form_controller.dart';
import '../widgets/electronic_leave_form_field.dart';
import '../widgets/electronic_leave_form_row.dart';

class ElectronicLeaveEmployeeInfoSection extends StatelessWidget {
  const ElectronicLeaveEmployeeInfoSection({
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
      title: isArabic ? 'بيانات الموظف' : 'Employee Information',
      child: Column(
        children: [
          ElectronicLeaveFormRow(
            children: [
              ElectronicLeaveFormField(
                controller: controller.employeeName,
                label: isArabic ? 'اسم الموظف' : 'Employee Name',
                readOnly: readOnly,
              ),
              ElectronicLeaveFormField(
                controller: controller.employeeId,
                label: isArabic ? 'الرقم الوظيفي' : 'Employee ID',
                readOnly: readOnly,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElectronicLeaveFormRow(
            children: [
              ElectronicLeaveFormField(
                controller: controller.applicationDate,
                label: isArabic ? 'تاريخ التقديم' : 'Application Date',
                readOnly: readOnly,
              ),
              ElectronicLeaveFormField(
                controller: controller.position,
                label: isArabic ? 'المسمى الوظيفي' : 'Job Title',
                readOnly: readOnly,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
