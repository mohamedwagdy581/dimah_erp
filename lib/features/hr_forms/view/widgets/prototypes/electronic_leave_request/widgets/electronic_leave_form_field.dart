import 'package:flutter/material.dart';

import '../../shared/electronic_form_theme.dart';

class ElectronicLeaveFormField extends StatelessWidget {
  const ElectronicLeaveFormField({
    super.key,
    required this.controller,
    required this.label,
    this.minLines = 1,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final int minLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ElectronicFormColors.inputBackground,
        borderRadius: BorderRadius.circular(
          ElectronicFormDimensions.inputBorderRadius,
        ),
        border: Border.all(color: ElectronicFormColors.inputBorder),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ElectronicFormDimensions.inputPaddingHorizontal,
        vertical: ElectronicFormDimensions.inputPaddingVertical,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ElectronicFormTextStyles.inputLabel),
          const SizedBox(height: ElectronicFormDimensions.inputFieldSpacing),
          TextField(
            controller: controller,
            minLines: minLines,
            maxLines: minLines,
            readOnly: readOnly,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
