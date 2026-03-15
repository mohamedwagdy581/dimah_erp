import 'package:flutter/material.dart';

class PortalBadge extends StatelessWidget {
  const PortalBadge({super.key, required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
