import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/attendance_import_record.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/repos/attendance_repo.dart';

class AttendanceRepoImpl implements AttendanceRepo {
  AttendanceRepoImpl(this._client);
  final SupabaseClient _client;

  bool _isManagerRole(String role) =>
      role.trim().toLowerCase() == 'manager' ||
      role.trim().toLowerCase() == 'direct_manager';

  Future<String> _tenantId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final me = await _client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();

    final t = me['tenant_id'];
    if (t == null) throw Exception('Missing tenant_id for current user');
    return t.toString();
  }

  String _toDateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

  Future<({String role, String? employeeId})> _currentUserIdentity() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    final me = await _client
        .from('users')
        .select('role, employee_id')
        .eq('id', uid)
        .single();
    return (
      role: (me['role'] ?? 'employee').toString(),
      employeeId: me['employee_id']?.toString(),
    );
  }

  Future<List<String>> _subordinateEmployeeIds({
    required String tenantId,
    required String managerEmployeeId,
  }) async {
    final directRes = await _client
        .from('employees')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('manager_id', managerEmployeeId);
    final directIds = (directRes as List).map((e) => e['id'].toString()).toList();

    final managedDepartmentsRes = await _client
        .from('departments')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('manager_id', managerEmployeeId);
    final managedDepartmentIds = (managedDepartmentsRes as List)
        .map((e) => e['id'].toString())
        .toList();

    final deptIds = <String>[];
    if (managedDepartmentIds.isNotEmpty) {
      final deptRes = await _client
          .from('employees')
          .select('id')
          .eq('tenant_id', tenantId)
          .inFilter('department_id', managedDepartmentIds);
      deptIds.addAll((deptRes as List).map((e) => e['id'].toString()));
    }

    final all = {...directIds, ...deptIds};
    all.remove(managerEmployeeId);
    return all.toList();
  }

  @override
  Future<({List<AttendanceRecord> items, int total})> fetchAttendance({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    DateTime? date,
    String? employeeId,
    String sortBy = 'date',
    bool ascending = false,
  }) async {
    final tenantId = await _tenantId();
    final actor = await _currentUserIdentity();
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final s = search?.trim();

    dynamic listQ = _client
        .from('attendance_records')
        .select(
          'id, tenant_id, employee_id, date, status, check_in, check_out, notes, created_at, '
          'employee:employees(full_name)',
        )
        .eq('tenant_id', tenantId);

    if ((employeeId == null || employeeId.trim().isEmpty) &&
        _isManagerRole(actor.role) &&
        actor.employeeId != null &&
        actor.employeeId!.isNotEmpty) {
      final subordinateIds = await _subordinateEmployeeIds(
        tenantId: tenantId,
        managerEmployeeId: actor.employeeId!,
      );
      if (subordinateIds.isEmpty) {
        return (items: const <AttendanceRecord>[], total: 0);
      }
      listQ = listQ.inFilter('employee_id', subordinateIds);
    }

    if (status != null && status.trim().isNotEmpty) {
      listQ = listQ.eq('status', status);
    }

    if (date != null) {
      listQ = listQ.eq('date', _toDateOnly(date));
    }

    if (employeeId != null && employeeId.trim().isNotEmpty) {
      listQ = listQ.eq('employee_id', employeeId);
    }

    if (s != null && s.isNotEmpty) {
      final escaped = s.replaceAll('%', r'\%').replaceAll('_', r'\_');
      listQ = listQ.or('employee.full_name.ilike.%$escaped%');
    }

    listQ = listQ.order(sortBy, ascending: ascending).range(from, to);

    final listRes = await listQ;
    final items = (listRes as List)
        .map((e) => AttendanceRecord.fromMap(e as Map<String, dynamic>))
        .toList();

    dynamic countQ = _client
        .from('attendance_records')
        .select('id')
        .eq('tenant_id', tenantId);

    if ((employeeId == null || employeeId.trim().isEmpty) &&
        _isManagerRole(actor.role) &&
        actor.employeeId != null &&
        actor.employeeId!.isNotEmpty) {
      final subordinateIds = await _subordinateEmployeeIds(
        tenantId: tenantId,
        managerEmployeeId: actor.employeeId!,
      );
      if (subordinateIds.isEmpty) {
        return (items: items, total: 0);
      }
      countQ = countQ.inFilter('employee_id', subordinateIds);
    }

    if (status != null && status.trim().isNotEmpty) {
      countQ = countQ.eq('status', status);
    }

    if (date != null) {
      countQ = countQ.eq('date', _toDateOnly(date));
    }

    if (employeeId != null && employeeId.trim().isNotEmpty) {
      countQ = countQ.eq('employee_id', employeeId);
    }

    if (s != null && s.isNotEmpty) {
      final escaped = s.replaceAll('%', r'\%').replaceAll('_', r'\_');
      countQ = countQ.or('employee.full_name.ilike.%$escaped%');
    }

    final countRes = await countQ;
    final total = (countRes as List).length;

    return (items: items, total: total);
  }

  @override
  Future<void> createAttendance({
    required String employeeId,
    required DateTime date,
    required String status,
    DateTime? checkIn,
    DateTime? checkOut,
    String? notes,
  }) async {
    final tenantId = await _tenantId();

    await _client.from('attendance_records').insert({
      'tenant_id': tenantId,
      'employee_id': employeeId,
      'date': _toDateOnly(date),
      'status': status,
      'check_in': checkIn?.toIso8601String(),
      'check_out': checkOut?.toIso8601String(),
      'notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
    });
  }

  @override
  Future<void> createCorrectionRequest({
    required String recordId,
    required String employeeId,
    required DateTime date,
    DateTime? proposedCheckIn,
    DateTime? proposedCheckOut,
    String? reason,
  }) async {
    final tenantId = await _tenantId();

    await _client.from('approval_requests').insert({
      'tenant_id': tenantId,
      'request_type': 'attendance_correction',
      'employee_id': employeeId,
      'status': 'pending',
      'payload': {
        'record_id': recordId,
        'date': _toDateOnly(date),
        'proposed_check_in': proposedCheckIn?.toIso8601String(),
        'proposed_check_out': proposedCheckOut?.toIso8601String(),
        'reason': (reason == null || reason.trim().isEmpty)
            ? null
            : reason.trim(),
      },
    });
  }

  @override
  Future<void> upsertAttendanceBatch(List<AttendanceImportRecord> records) async {
    if (records.isEmpty) return;

    final tenantId = await _tenantId();
    final employeeIds = records.map((e) => e.employeeId).toSet().toList();
    final days = records.map((e) => _toDateOnly(e.date)).toList();
    days.sort();
    final minDay = days.first;
    final maxDay = days.last;

    dynamic existingQ = _client
        .from('attendance_records')
        .select('id, employee_id, date')
        .eq('tenant_id', tenantId)
        .gte('date', minDay)
        .lte('date', maxDay);

    if (employeeIds.isNotEmpty) {
      existingQ = existingQ.inFilter('employee_id', employeeIds);
    }

    final existingRes = await existingQ;
    final existingByKey = <String, String>{};
    for (final row in (existingRes as List)) {
      final map = row as Map<String, dynamic>;
      final key = '${map['employee_id']}|${map['date']}';
      existingByKey.putIfAbsent(key, () => map['id'].toString());
    }

    for (final record in records) {
      final day = _toDateOnly(record.date);
      final key = '${record.employeeId}|$day';
      final payload = {
        'tenant_id': tenantId,
        'employee_id': record.employeeId,
        'date': day,
        'status': record.status,
        'check_in': record.checkIn?.toIso8601String(),
        'check_out': record.checkOut?.toIso8601String(),
        'notes': (record.notes == null || record.notes!.trim().isEmpty)
            ? null
            : record.notes!.trim(),
      };

      final existingId = existingByKey[key];
      if (existingId == null) {
        await _client.from('attendance_records').insert(payload);
      } else {
        await _client
            .from('attendance_records')
            .update(payload)
            .eq('id', existingId);
      }
    }
  }
}
