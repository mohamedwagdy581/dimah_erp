import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class ApprovalsTableEmpty extends StatelessWidget {
  const ApprovalsTableEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: AppEmptyState(title: t.noApprovalsFound, compact: false),
        ),
      ),
    );
  }
}
