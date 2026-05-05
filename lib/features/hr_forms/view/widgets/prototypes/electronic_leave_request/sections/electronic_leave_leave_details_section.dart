import 'package:flutter/material.dart';

import '../../shared/electronic_form_theme.dart';
import '../../shared/electronic_section_card.dart';
import '../electronic_leave_request_form_controller.dart';
import '../widgets/electronic_leave_form_field.dart';
import '../widgets/electronic_leave_form_row.dart';

class ElectronicLeaveDetailsSection extends StatelessWidget {
  const ElectronicLeaveDetailsSection({
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
      title: isArabic ? 'تفاصيل الإجازة' : 'Leave Details',
      child: Column(
        children: [
          ElectronicLeaveFormRow(
            children: [
              ElectronicLeaveFormField(
                controller: controller.leaveType,
                label: isArabic ? 'نوع الإجازة' : 'Leave Type',
                readOnly: readOnly,
              ),
              ElectronicLeaveFormField(
                controller: controller.days,
                label: isArabic ? 'عدد الأيام' : 'No. of Days',
                readOnly: readOnly,
              ),
            ],
          ),
          const SizedBox(height: ElectronicFormDimensions.sectionSpacing),
          ElectronicLeaveFormRow(
            children: [
              ElectronicLeaveFormField(
                controller: controller.fromDate,
                label: isArabic ? 'من تاريخ' : 'From Date',
                readOnly: readOnly,
              ),
              ElectronicLeaveFormField(
                controller: controller.toDate,
                label: isArabic ? 'إلى تاريخ' : 'To Date',
                readOnly: readOnly,
              ),
            ],
          ),
          const SizedBox(height: ElectronicFormDimensions.sectionSpacing),
          ElectronicLeaveFormRow(
            children: [
              ElectronicLeaveFormField(
                controller: controller.addressDuringLeave,
                label: isArabic
                    ? 'العنوان أثناء الإجازة'
                    : 'Address During Leave',
                readOnly: readOnly,
              ),
              ElectronicLeaveFormField(
                controller: controller.contactDuringLeave,
                label: isArabic
                    ? 'التواصل أثناء الإجازة'
                    : 'Contact During Leave',
                readOnly: readOnly,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
