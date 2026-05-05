import 'package:flutter/material.dart';

import 'electronic_form_theme.dart';

class ElectronicSectionCard extends StatelessWidget {
  const ElectronicSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.hint,
  });

  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: ElectronicFormDimensions.sectionSpacing,
      ),
      decoration: ElectronicFormDecorations.sectionDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ElectronicFormDimensions.sectionPadding,
              vertical: ElectronicFormDimensions.sectionPadding * 0.625,
            ),
            decoration: ElectronicFormDecorations.sectionHeaderDecoration,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: ElectronicFormTextStyles.sectionTitle,
                  ),
                ),
                if (hint != null)
                  Text(hint!, style: ElectronicFormTextStyles.sectionHint),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(
              ElectronicFormDimensions.sectionPadding,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
