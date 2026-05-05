import 'package:flutter/material.dart';

import '../../shared/electronic_form_theme.dart';

class ElectronicAcknowledgmentClauseCard extends StatelessWidget {
  const ElectronicAcknowledgmentClauseCard({
    super.key,
    required this.index,
    required this.title,
    required this.body,
  });

  final String index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ElectronicFormColors.inputBackgroundSecondary,
        borderRadius: BorderRadius.circular(
          ElectronicFormDimensions.inputBorderRadius,
        ),
        border: Border.all(color: ElectronicFormColors.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF3B8D72),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              index,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: ElectronicFormDimensions.rowSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF264E43),
                  ),
                ),
                const SizedBox(
                  height: ElectronicFormDimensions.inputFieldSpacing * 2,
                ),
                Text(
                  body,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
