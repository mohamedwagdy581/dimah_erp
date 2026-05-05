import 'package:flutter/material.dart';

import '../../shared/electronic_form_theme.dart';

class ElectronicLeaveFormRow extends StatelessWidget {
  const ElectronicLeaveFormRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1)
            const SizedBox(width: ElectronicFormDimensions.rowSpacing),
        ],
      ],
    );
  }
}
