import 'package:flutter/material.dart';

import '../../shared/electronic_form_theme.dart';
import '../../shared/electronic_section_card.dart';
import '../electronic_acknowledgment_form_controller.dart';

class ElectronicAcknowledgmentAutoFillSection extends StatelessWidget {
  const ElectronicAcknowledgmentAutoFillSection({
    super.key,
    required this.controller,
    required this.isArabic,
    this.onSelectEmployee,
    this.onClearSelection,
  });

  final ElectronicAcknowledgmentFormController controller;
  final bool isArabic;
  final ValueChanged<String>? onSelectEmployee;
  final VoidCallback? onClearSelection;

  @override
  Widget build(BuildContext context) {
    return ElectronicSectionCard(
      title: isArabic ? 'التعبئة التلقائية' : 'Auto Fill',
      hint: isArabic ? 'اختياري' : 'Optional',
      child: Wrap(
        spacing: ElectronicFormDimensions.rowSpacing,
        runSpacing: ElectronicFormDimensions.rowSpacing,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: ElectronicFormDimensions.iconSize,
            color: ElectronicFormColors.headingText,
          ),
          Text(
            isArabic
                ? 'اختيار موظف للتعبئة التلقائية'
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
                  borderSide: const BorderSide(
                    color: ElectronicFormColors.inputBorder,
                  ),
                ),
                labelText: isArabic ? 'اختيار موظف' : 'Select employee',
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
            label: Text(isArabic ? 'إلغاء الربط' : 'Clear selection'),
          ),
        ],
      ),
    );
  }
}
