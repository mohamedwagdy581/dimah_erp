import 'package:flutter/material.dart';

import '../../shared/electronic_form_theme.dart';
import '../../shared/electronic_section_card.dart';
import '../electronic_leave_request_form_controller.dart';

class ElectronicLeaveAutoFillSection extends StatelessWidget {
  const ElectronicLeaveAutoFillSection({
    super.key,
    required this.controller,
    required this.isArabic,
    this.onSelectEmployee,
    this.onClearSelection,
  });

  final ElectronicLeaveRequestFormController controller;
  final bool isArabic;
  final ValueChanged<String>? onSelectEmployee;
  final VoidCallback? onClearSelection;

  @override
  Widget build(BuildContext context) {
    return ElectronicSectionCard(
      title: isArabic ? 'التعبئة التلقائية' : 'Auto Fill',
      hint: isArabic ? 'اختياري' : 'Optional',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            Icons.person_search_outlined,
            color: ElectronicFormColors.accentIcon,
            size: ElectronicFormDimensions.iconSize,
          ),
          Text(
            isArabic
                ? 'اختر الموظف للتعبئة التلقائية'
                : 'Select employee for auto-fill',
            style: ElectronicFormTextStyles.sectionLabel,
          ),
          SizedBox(
            width: ElectronicFormDimensions.dropdownWidth,
            child: DropdownButtonFormField<String>(
              initialValue: controller.selectedEmployeeId,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ElectronicFormDimensions.inputBorderRadius,
                  ),
                ),
                labelText: isArabic ? 'اختر الموظف' : 'Select employee',
              ),
              items: controller.employeeOptions
                  .map(
                    (employee) => DropdownMenuItem(
                      value: employee.id,
                      child: Text(
                        employee.fullName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onSelectEmployee == null
                  ? null
                  : (value) {
                      if (value != null) onSelectEmployee!(value);
                    },
            ),
          ),
          if (controller.loadingEmployees || controller.fillingEmployee)
            SizedBox(
              width: ElectronicFormDimensions.iconSize,
              height: ElectronicFormDimensions.iconSize,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          TextButton.icon(
            onPressed: onClearSelection,
            icon: const Icon(Icons.restart_alt),
            label: Text(isArabic ? 'مسح التعبئة' : 'Clear selection'),
          ),
        ],
      ),
    );
  }
}
