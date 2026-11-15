import 'package:flutter/material.dart';

class ProfileKvRow extends StatelessWidget {
  const ProfileKvRow({super.key, required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final text = (value == null || value!.trim().isEmpty) ? '-' : value!.trim();
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FD),
        border: Border.all(color: const Color(0xFFECE7F5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            style: const TextStyle(fontSize: 12, color: Color(0xFF66638B)),
          ),
          const SizedBox(height: 7),
          SelectableText(
            text,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
