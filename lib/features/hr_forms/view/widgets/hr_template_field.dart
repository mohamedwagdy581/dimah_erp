import 'package:flutter/material.dart';

class HrTemplateField extends StatelessWidget {
  const HrTemplateField({
    super.key,
    required this.label,
    required this.controller,
    this.textAlign = TextAlign.center,
    this.minLines = 1,
    this.maxLines = 1,
    this.fontWeight,
    this.fontSize = 14,
  });

  final String label;
  final TextEditingController controller;
  final TextAlign textAlign;
  final int minLines;
  final int maxLines;
  final FontWeight? fontWeight;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final hasLabel = label.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black54, width: .8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasLabel)
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          if (hasLabel) const SizedBox(height: 6),
          TextField(
            controller: controller,
            textAlign: textAlign,
            minLines: minLines,
            maxLines: maxLines,
            decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
            style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
          ),
        ],
      ),
    );
  }
}
