part of 'attendance_repo_impl.dart';

mixin _AttendanceRepoActionsMixin on _AttendanceRepoFetchMixin {
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
      'notes': _normalizeOptionalText(notes),
    });
  }

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
        'reason': _normalizeOptionalText(reason),
      },
    });
  }

  Future<void> upsertAttendanceBatch(List<AttendanceImportRecord> records) async {
    if (records.isEmpty) return;

    final tenantId = await _tenantId();
    final employeeIds = records.map((e) => e.employeeId).toSet().toList();
    final days = records.map((e) => _toDateOnly(e.date)).toList()..sort();
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

    final existingByKey = <String, String>{};
    for (final row in (await existingQ as List)) {
      final map = row as Map<String, dynamic>;
      existingByKey.putIfAbsent(
        '${map['employee_id']}|${map['date']}',
        () => map['id'].toString(),
      );
    }

    for (final record in records) {
      final day = _toDateOnly(record.date);
      final payload = {
        'tenant_id': tenantId,
        'employee_id': record.employeeId,
        'date': day,
        'status': record.status,
        'check_in': record.checkIn?.toIso8601String(),
        'check_out': record.checkOut?.toIso8601String(),
        'notes': _normalizeOptionalText(record.notes),
      };

      final existingId = existingByKey['${record.employeeId}|$day'];
      if (existingId == null) {
        await _client.from('attendance_records').insert(payload);
      } else {
        await _client.from('attendance_records').update(payload).eq('id', existingId);
      }
    }
  }
}
