part of 'dashboard_page.dart';

extension _HrDashboardAttendanceHelpers on _HrDashboardState {
  Future<({
    int checkedInToday,
    int missingCheckInToday,
    int lateToday,
    int overtimeToday,
    List<_AttendanceAttentionItem> todayAttentionItems,
  })> _loadAttendanceInsights(
    SupabaseClient client,
    String tenantId,
    String todayStr,
    int activeEmployees,
  ) async {
    final todayAttendanceRes = await client
        .from('attendance_records')
        .select('employee_id, check_in, check_out, status, employee:employees(full_name)')
        .eq('tenant_id', tenantId)
        .eq('date', todayStr);
    final rows = (todayAttendanceRes as List);
    final checkedInIds = rows.where((row) => row['check_in'] != null).map((row) => row['employee_id'].toString()).toSet();
    final attentionItems = rows
        .map((row) {
          final employee = row['employee'];
          final employeeName = employee is Map ? (employee['full_name'] ?? '-').toString() : '-';
          final lateMinutes = _lateMinutesFromRow(row['check_in']);
          final overtimeMinutes = _overtimeMinutesFromRow(row['check_out']);
          if (lateMinutes > 0) {
            return _AttendanceAttentionItem(employeeName: employeeName, type: 'late', valueLabel: '${lateMinutes}m', value: lateMinutes);
          }
          if (overtimeMinutes > 0) {
            return _AttendanceAttentionItem(employeeName: employeeName, type: 'overtime', valueLabel: '${overtimeMinutes}m', value: overtimeMinutes);
          }
          return null;
        })
        .whereType<_AttendanceAttentionItem>()
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return (
      checkedInToday: checkedInIds.length,
      missingCheckInToday: activeEmployees - checkedInIds.length,
      lateToday: rows.where((row) => (row['status'] ?? '').toString().toLowerCase() == 'late').length,
      overtimeToday: rows.where((row) => _overtimeMinutesFromRow(row['check_out']) > 0).length,
      todayAttentionItems: attentionItems.take(8).toList(),
    );
  }
  int _lateMinutesFromRow(dynamic value) {
    if (value == null) return 0;
    final checkIn = DateTime.tryParse(value.toString());
    if (checkIn == null) return 0;
    final workStart = DateTime(checkIn.year, checkIn.month, checkIn.day, 9, 15);
    if (!checkIn.isAfter(workStart)) return 0;
    return checkIn.difference(workStart).inMinutes;
  }

  int _overtimeMinutesFromRow(dynamic value) {
    if (value == null) return 0;
    final checkOut = DateTime.tryParse(value.toString());
    if (checkOut == null) return 0;
    final workEnd = DateTime(checkOut.year, checkOut.month, checkOut.day, 17, 0);
    if (!checkOut.isAfter(workEnd)) return 0;
    return checkOut.difference(workEnd).inMinutes;
  }
}
