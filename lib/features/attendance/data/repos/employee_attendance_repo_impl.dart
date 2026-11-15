import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/repos/employee_attendance_repo.dart';

class EmployeeAttendanceRepoImpl implements EmployeeAttendanceRepo {
  EmployeeAttendanceRepoImpl(this.client);
  final SupabaseClient client;
  @override
  Future<EmployeeAttendanceMonth> fetchMonth({
    required String employeeId,
    required DateTime month,
  }) async {
    final start = DateTime(month.year, month.month);
    final date = start.toIso8601String().split('T').first;
    try {
      final response = Map<String, dynamic>.from(
        await client.rpc('employee_attendance_month', params: {'p_month': date})
            as Map,
      );
      final records = (response['records'] as List)
          .map(
            (r) =>
                AttendanceRecord.fromMap(Map<String, dynamic>.from(r as Map)),
          )
          .toList();
      if (records.any((r) => r.employeeId != employeeId)) {
        throw StateError('Employee session changed');
      }
      return EmployeeAttendanceMonth(
        records: records,
        pendingRecordIds: (response['pending_record_ids'] as List)
            .map((v) => v.toString())
            .toSet(),
      );
    } on PostgrestException catch (error) {
      // Read compatibility only. Writes always use the validated database RPC.
      if (error.code != 'PGRST202') rethrow;
      final uid = client.auth.currentUser?.id;
      if (uid == null) throw StateError('Not authenticated');
      final actor = await client
          .from('users')
          .select('tenant_id, employee_id, role, is_active')
          .eq('id', uid)
          .single();
      if (actor['role'] != 'employee' ||
          actor['is_active'] != true ||
          actor['employee_id'] != employeeId) {
        throw StateError('Invalid employee session');
      }
      final records = <AttendanceRecord>[];
      final next = DateTime(
        start.year,
        start.month + 1,
      ).toIso8601String().split('T').first;
      for (var page = 0; ; page++) {
        final rows = await client
            .from('attendance_records')
            .select()
            .eq('tenant_id', actor['tenant_id'])
            .eq('employee_id', employeeId)
            .gte('date', date)
            .lt('date', next)
            .order('date', ascending: false)
            .order('id')
            .range(page * 100, page * 100 + 99);
        records.addAll(rows.map(AttendanceRecord.fromMap));
        if (rows.length < 100) break;
      }
      return EmployeeAttendanceMonth(records: records, correctionsReady: false);
    }
  }

  @override
  Future<void> requestCorrection({
    required AttendanceRecord record,
    required DateTime checkIn,
    required DateTime checkOut,
    required String reason,
  }) async {
    await client.rpc(
      'employee_request_attendance_correction',
      params: {
        'p_record_id': record.id,
        'p_check_in': checkIn.toUtc().toIso8601String(),
        'p_check_out': checkOut.toUtc().toIso8601String(),
        'p_reason': reason.trim(),
      },
    );
  }
}
