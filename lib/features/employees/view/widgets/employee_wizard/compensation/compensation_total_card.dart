import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';

class CompensationTotalCard extends StatelessWidget {
  const CompensationTotalCard({super.key, required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(t.total, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(
            t.amountSar(total.toStringAsFixed(2)),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
