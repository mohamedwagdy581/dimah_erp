import 'package:flutter/material.dart';

class ProfileKvRow extends StatelessWidget {
  const ProfileKvRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = (value == null || value!.trim().isEmpty) ? '-' : value!.trim();
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isRtl
            ? [
                SizedBox(
                  width: 170,
                  child: Text(
                    '$label:',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ]
            : [
                SizedBox(
                  width: 170,
                  child: Text(
                    '$label:',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(text, textAlign: TextAlign.left)),
              ],
      ),
    );
  }
}
