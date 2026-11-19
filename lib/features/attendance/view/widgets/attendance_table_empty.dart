import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';

class AttendanceTableEmpty extends StatelessWidget {
  const AttendanceTableEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: AppEmptyState(
            title: t.noAttendanceRecordsFound,
            compact: false,
          ),
        ),
      ),
    );
  }
}
