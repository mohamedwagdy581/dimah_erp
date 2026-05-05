import 'package:flutter/material.dart';

import '../../shared/electronic_form_theme.dart';

class ElectronicAcknowledgmentInfoChip extends StatelessWidget {
  const ElectronicAcknowledgmentInfoChip({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: ElectronicFormTextStyles.sectionLabel.copyWith(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
