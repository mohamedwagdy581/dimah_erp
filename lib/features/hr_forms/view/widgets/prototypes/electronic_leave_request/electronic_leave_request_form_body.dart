import 'package:flutter/material.dart';

import '../shared/electronic_form_frame.dart';
import 'electronic_leave_request_form_controller.dart';
import 'sections/electronic_leave_auto_fill_section.dart';
import 'sections/electronic_leave_coverage_section.dart';
import 'sections/electronic_leave_employee_info_section.dart';
import 'sections/electronic_leave_hr_use_section.dart';
import 'sections/electronic_leave_leave_details_section.dart';

class ElectronicLeaveRequestFormBody extends StatelessWidget {
  const ElectronicLeaveRequestFormBody({
    super.key,
    required this.controller,
    required this.isArabic,
    required this.readOnly,
    this.onClear,
    this.onOpenPreview,
    this.onSelectEmployee,
    this.onClearSelection,
  });

  final ElectronicLeaveRequestFormController controller;
  final bool isArabic;
  final bool readOnly;
  final VoidCallback? onClear;
  final VoidCallback? onOpenPreview;
  final ValueChanged<String>? onSelectEmployee;
  final VoidCallback? onClearSelection;

  @override
  Widget build(BuildContext context) {
    return ElectronicFormFrame(
      title: isArabic ? 'طلب إجازة' : 'Leave Request',
      subtitle: isArabic
          ? 'نسخة تصميمية للتجربة قبل اعتماد الشكل النهائي'
          : 'Design prototype before final approval',
      showDecoration: readOnly,
      headerLogo: Image.asset('assets/images/fullLogo.png', width: 80),
      actions: readOnly
          ? const []
          : [
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.refresh),
                label: Text(isArabic ? 'تفريغ' : 'Clear'),
              ),
              FilledButton.icon(
                onPressed: onOpenPreview,
                icon: const Icon(Icons.preview_outlined),
                label: Text(isArabic ? 'طباعة / PDF' : 'Print / PDF'),
              ),
            ],
      child: Column(
        children: [
          if (!readOnly)
            ElectronicLeaveAutoFillSection(
              controller: controller,
              isArabic: isArabic,
              onSelectEmployee: onSelectEmployee,
              onClearSelection: onClearSelection,
            ),
          ElectronicLeaveEmployeeInfoSection(
            controller: controller,
            isArabic: isArabic,
            readOnly: readOnly,
          ),
          ElectronicLeaveDetailsSection(
            controller: controller,
            isArabic: isArabic,
            readOnly: readOnly,
          ),
          ElectronicLeaveCoverageSection(
            controller: controller,
            isArabic: isArabic,
            readOnly: readOnly,
          ),
          ElectronicLeaveHrUseSection(
            controller: controller,
            isArabic: isArabic,
            readOnly: readOnly,
          ),
        ],
      ),
    );
  }
}
