import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/attendance_record.dart';

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
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text(t.noAttendanceRecordsFound)),
        ),
      );
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
                  final lateMinutes = _lateMinutes(r.checkIn);
                  final overtimeMinutes = _overtimeMinutes(r.checkOut);
                  final rowColor = lateMinutes > 0
                      ? Colors.orange.withValues(alpha: 0.06)
                      : (overtimeMinutes > 0
                            ? Colors.blue.withValues(alpha: 0.06)
                            : Colors.transparent);
                  return DataRow(
                    color: WidgetStatePropertyAll(rowColor),
                    cells: [
                      DataCell(Text(r.employeeName)),
                      DataCell(Text(_formatDate(r.date))),
                      DataCell(_statusChip(context, r.status)),
                      DataCell(Text(_formatTime(r.checkIn))),
                      DataCell(Text(_formatTime(r.checkOut))),
                      DataCell(
                        Text(
                          lateMinutes == 0 ? '-' : '${lateMinutes}m',
                          style: TextStyle(
                            color: lateMinutes > 0 ? Colors.orange : null,
                            fontWeight: lateMinutes > 0
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          overtimeMinutes == 0 ? '-' : '${overtimeMinutes}m',
                          style: TextStyle(
                            color: overtimeMinutes > 0 ? Colors.lightBlue : null,
                            fontWeight: overtimeMinutes > 0
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      DataCell(Text(r.notes ?? '-')),
                      DataCell(
                        TextButton(
                          onPressed: () => onRequestCorrection(r),
                          child: Text(t.requestCorrection),
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

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime? d) {
    if (d == null) return '-';
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  int _lateMinutes(DateTime? checkIn) {
    if (checkIn == null) return 0;
    final workStart = DateTime(
      checkIn.year,
      checkIn.month,
      checkIn.day,
      9,
      15,
    );
    if (!checkIn.isAfter(workStart)) return 0;
    return checkIn.difference(workStart).inMinutes;
  }

  int _overtimeMinutes(DateTime? checkOut) {
    if (checkOut == null) return 0;
    final workEnd = DateTime(checkOut.year, checkOut.month, checkOut.day, 17, 0);
    if (!checkOut.isAfter(workEnd)) return 0;
    return checkOut.difference(workEnd).inMinutes;
  }

  Widget _statusChip(BuildContext context, String status) {
    final t = AppLocalizations.of(context)!;
    final s = status.toLowerCase();
    if (s == 'late') {
      return Chip(
        label: Text(t.attendanceLate),
        backgroundColor: Color(0x33FF9800),
      );
    }
    if (s == 'absent') {
      return Chip(
        label: Text(t.attendanceAbsent),
        backgroundColor: Color(0x33F44336),
      );
    }
    if (s == 'on_leave') {
      return Chip(
        label: Text(t.attendanceOnLeave),
        backgroundColor: Color(0x339C27B0),
      );
    }
    return Chip(
      label: Text(t.attendancePresent),
      backgroundColor: Color(0x334CAF50),
    );
  }
}
