import 'package:flutter/material.dart';

import '../shared/electronic_form_frame.dart';
import 'electronic_acknowledgment_form_controller.dart';
import 'sections/electronic_acknowledgment_approval_section.dart';
import 'sections/electronic_acknowledgment_auto_fill_section.dart';
import 'sections/electronic_acknowledgment_clauses_section.dart';
import 'sections/electronic_acknowledgment_employee_info_section.dart';
import 'sections/electronic_acknowledgment_summary_section.dart';

class ElectronicAcknowledgmentFormBody extends StatelessWidget {
  const ElectronicAcknowledgmentFormBody({
    super.key,
    required this.controller,
    required this.isArabic,
    required this.readOnly,
    this.onClear,
    this.onOpenPreview,
    this.onSelectEmployee,
    this.onClearSelection,
  });

  final ElectronicAcknowledgmentFormController controller;
  final bool isArabic;
  final bool readOnly;
  final VoidCallback? onClear;
  final VoidCallback? onOpenPreview;
  final ValueChanged<String>? onSelectEmployee;
  final VoidCallback? onClearSelection;

  @override
  Widget build(BuildContext context) {
    return ElectronicFormFrame(
      title: isArabic ? 'إقرار وتعهد الموظف' : 'Employee Acknowledgment',
      subtitle: isArabic
          ? 'تصميم إلكتروني مرن لمراجعة العميل واعتماد الاتجاه البصري'
          : 'A flexible electronic layout for client review and visual direction approval',
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
          if (!readOnly) ...[
            ElectronicAcknowledgmentAutoFillSection(
              controller: controller,
              isArabic: isArabic,
              onSelectEmployee: onSelectEmployee,
              onClearSelection: onClearSelection,
            ),
            ElectronicAcknowledgmentSummarySection(isArabic: isArabic),
          ],
          ElectronicAcknowledgmentEmployeeInfoSection(
            controller: controller,
            isArabic: isArabic,
            readOnly: readOnly,
          ),
          ElectronicAcknowledgmentClausesSection(isArabic: isArabic),
          ElectronicAcknowledgmentApprovalSection(
            controller: controller,
            isArabic: isArabic,
            readOnly: readOnly,
          ),
        ],
      ),
    );
  }
}
