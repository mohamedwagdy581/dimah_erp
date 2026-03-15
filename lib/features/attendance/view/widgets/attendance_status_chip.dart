import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class AttendanceStatusChip extends StatelessWidget {
  const AttendanceStatusChip({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final s = status.toLowerCase();
    if (s == 'late') {
      return Chip(
        label: Text(t.attendanceLate),
        backgroundColor: const Color(0x33FF9800),
      );
    }
    if (s == 'absent') {
      return Chip(
        label: Text(t.attendanceAbsent),
        backgroundColor: const Color(0x33F44336),
      );
    }
    if (s == 'on_leave') {
      return Chip(
        label: Text(t.attendanceOnLeave),
        backgroundColor: const Color(0x339C27B0),
      );
    }
    return Chip(
      label: Text(t.attendancePresent),
      backgroundColor: const Color(0x334CAF50),
    );
  }
}
