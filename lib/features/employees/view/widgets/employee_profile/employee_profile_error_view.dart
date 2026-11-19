import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:material_ui/material_ui.dart';

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
    return AppFailureState(
      error: error,
      onRetry: onRetry,
      title: t.failedToLoadEmployeeProfile,
    );
  }
}
