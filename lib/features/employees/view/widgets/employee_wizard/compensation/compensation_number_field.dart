import 'package:flutter/material.dart';

class CompensationNumberField extends StatelessWidget {
  const CompensationNumberField({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
