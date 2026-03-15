part of 'attendance_import_dialog.dart';

extension _AttendanceImportDialogTable on _AttendanceImportDialogState {
  Widget _buildTable(List<_PreviewRow> visible) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Person ID')),
              DataColumn(label: Text('Name (CSV)')),
              DataColumn(label: Text('Employee (ERP)')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Check In')),
              DataColumn(label: Text('Check Out')),
              DataColumn(label: Text('Late')),
              DataColumn(label: Text('Overtime')),
              DataColumn(label: Text('Status')),
            ],
            rows: visible.map(_buildRow).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(_PreviewRow row) {
    final rowColor = row.isMatched
        ? (row.lateMinutes > 0
            ? Colors.orange.withValues(alpha: 0.08)
            : (row.overtimeMinutes > 0
                ? Colors.blue.withValues(alpha: 0.08)
                : Colors.transparent))
        : Colors.red.withValues(alpha: 0.08);

    return DataRow(
      color: WidgetStatePropertyAll(rowColor),
      cells: [
        DataCell(Text(row.sourcePersonId)),
        DataCell(Text(row.sourceName)),
        DataCell(Text(row.matchedEmployeeName ?? 'Not matched')),
        DataCell(Text(_fmtDate(row.date))),
        DataCell(Text(_fmtTime(row.checkIn))),
        DataCell(Text(_fmtTime(row.checkOut))),
        DataCell(_metricText(row.lateMinutes, Colors.orange)),
        DataCell(_metricText(row.overtimeMinutes, Colors.lightBlue)),
        DataCell(_statusChip(row)),
      ],
    );
  }

  Widget _metricText(int minutes, Color color) {
    return Text(
      minutes == 0 ? '-' : '${minutes}m',
      style: TextStyle(
        color: minutes > 0 ? color : null,
        fontWeight: minutes > 0 ? FontWeight.w700 : FontWeight.w400,
      ),
    );
  }

  Widget _statusChip(_PreviewRow row) {
    if (!row.isMatched) {
      return const Chip(label: Text('Unmatched'), backgroundColor: Color(0x33F44336));
    }
    if (row.lateMinutes > 0) {
      return const Chip(label: Text('Late'), backgroundColor: Color(0x33FF9800));
    }
    if (row.overtimeMinutes > 0) {
      return const Chip(label: Text('Overtime'), backgroundColor: Color(0x332196F3));
    }
    return const Chip(label: Text('Present'), backgroundColor: Color(0x334CAF50));
  }

  String _fmtDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  String _fmtTime(DateTime? value) {
    if (value == null) return '-';
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:'
        '${value.second.toString().padLeft(2, '0')}';
  }
}
