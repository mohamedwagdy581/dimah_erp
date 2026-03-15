import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/leave_balance.dart';

class LeavesBalanceCards extends StatelessWidget {
  const LeavesBalanceCards({
    super.key,
    required this.balances,
    required this.t,
  });

  final List<LeaveBalance> balances;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: balances.map((balance) {
        return _BalanceCard(
          title: balance.type.toUpperCase(),
          entitlement: balance.entitlement,
          used: balance.used,
          remaining: balance.remaining,
          t: t,
        );
      }).toList(),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.title,
    required this.entitlement,
    required this.used,
    required this.remaining,
    required this.t,
  });

  final String title;
  final double entitlement;
  final double used;
  final double remaining;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final ok = remaining >= 0;
    return Container(
      width: 210,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(t.entitlementWithValue(entitlement.toStringAsFixed(0))),
          Text(t.usedWithValue(used.toStringAsFixed(0))),
          Text(
            t.remainingWithValue(remaining.toStringAsFixed(0)),
            style: TextStyle(
              color: ok ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
