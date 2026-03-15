import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class EmployeeProfileErrorView extends StatelessWidget {
  const EmployeeProfileErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.failedToLoadEmployeeProfile,
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(t.retry),
          ),
        ],
      ),
    );
  }
}
