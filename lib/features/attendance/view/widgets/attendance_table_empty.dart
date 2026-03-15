import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class AttendanceTableEmpty extends StatelessWidget {
  const AttendanceTableEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(t.noAttendanceRecordsFound)),
      ),
    );
  }
}
