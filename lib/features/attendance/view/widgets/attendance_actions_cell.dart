import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/attendance_record.dart';
import 'attendance_table_utils.dart';

class AttendanceActionsCell extends StatelessWidget {
  const AttendanceActionsCell({
    super.key,
    required this.record,
    required this.onRequestCorrection,
  });

  final AttendanceRecord record;
  final ValueChanged<AttendanceRecord> onRequestCorrection;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lateMinutes = attendanceLateMinutes(record.checkIn);
    final overtimeMinutes = attendanceOvertimeMinutes(record.checkOut);
    return Row(
      children: [
        _MetricText(
          value: lateMinutes == 0 ? '-' : '${lateMinutes}m',
          active: lateMinutes > 0,
          color: Colors.orange,
        ),
        const SizedBox(width: 12),
        _MetricText(
          value: overtimeMinutes == 0 ? '-' : '${overtimeMinutes}m',
          active: overtimeMinutes > 0,
          color: Colors.lightBlue,
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: () => onRequestCorrection(record),
          child: Text(t.requestCorrection),
        ),
      ],
    );
  }
}

class _MetricText extends StatelessWidget {
  const _MetricText({
    required this.value,
    required this.active,
    required this.color,
  });

  final String value;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        color: active ? color : null,
        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
      ),
    );
  }
}
