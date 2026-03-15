import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/attendance_record.dart';
import 'attendance_actions_cell.dart';
import 'attendance_status_chip.dart';
import 'attendance_table_empty.dart';
import 'attendance_table_utils.dart';

class AttendanceTable extends StatelessWidget {
  const AttendanceTable({
    super.key,
    required this.items,
    required this.onRequestCorrection,
  });

  final List<AttendanceRecord> items;
  final ValueChanged<AttendanceRecord> onRequestCorrection;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return const AttendanceTableEmpty();
    }

    return Card(
      child: LayoutBuilder(
        builder: (context, c) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: c.maxWidth),
              child: DataTable(
                columns: [
                  DataColumn(label: Text(t.employee)),
                  DataColumn(label: Text(t.date)),
                  DataColumn(label: Text(t.status)),
                  DataColumn(label: Text(t.checkIn)),
                  DataColumn(label: Text(t.checkOut)),
                  DataColumn(label: Text(t.attendanceLate)),
                  DataColumn(label: Text(t.overtime)),
                  DataColumn(label: Text(t.notes)),
                  DataColumn(label: Text(t.actions)),
                ],
                rows: items.map((r) {
                  return DataRow(
                    color: WidgetStatePropertyAll(attendanceRowColor(r)),
                    cells: [
                      DataCell(Text(r.employeeName)),
                      DataCell(Text(formatAttendanceDate(r.date))),
                      DataCell(AttendanceStatusChip(status: r.status)),
                      DataCell(Text(formatAttendanceTime(r.checkIn))),
                      DataCell(Text(formatAttendanceTime(r.checkOut))),
                      DataCell(Text(_lateLabel(r))),
                      DataCell(Text(_overtimeLabel(r))),
                      DataCell(Text(r.notes ?? '-')),
                      DataCell(
                        AttendanceActionsCell(
                          record: r,
                          onRequestCorrection: onRequestCorrection,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  String _lateLabel(AttendanceRecord record) {
    final minutes = attendanceLateMinutes(record.checkIn);
    return minutes == 0 ? '-' : '${minutes}m';
  }

  String _overtimeLabel(AttendanceRecord record) {
    final minutes = attendanceOvertimeMinutes(record.checkOut);
    return minutes == 0 ? '-' : '${minutes}m';
  }
}
