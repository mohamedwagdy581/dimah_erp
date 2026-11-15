import 'dart:convert';
import 'package:erp_sys/features/attendance/data/repos/attendance_repo_impl.dart';
import 'package:erp_sys/features/attendance/domain/models/attendance_import_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'employee_attendance_repo_test.dart' show server;

void main() {
  final checkIn = DateTime.parse('2026-09-27T10:02:00+03:00');
  final checkOut = DateTime.parse('2026-09-27T16:43:00+03:00');
  AttendanceImportRecord record() => AttendanceImportRecord(
    employeeId: 'employee',
    date: DateTime(2026, 9, 27),
    status: 'present',
    checkIn: checkIn,
    checkOut: checkOut,
    notes: 'Imported from biometric CSV (Person ID: 2)',
  );
  test(
    'New imports send unambiguous UTC instants while retaining device day',
    () async {
      Map? inserted;
      final client = await server((request) async {
        if (request.method == 'GET') {
          return [];
        }
        inserted = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
        request.response.statusCode = 201;
        return null;
      }, role: 'hr');
      await AttendanceRepoImpl(client).upsertAttendanceBatch([record()]);
      expect(inserted!['date'], '2026-09-27');
      expect(inserted!['check_in'], '2026-09-27T07:02:00.000Z');
      expect(inserted!['check_out'], '2026-09-27T13:43:00.000Z');
      // A local CSV DateTime must also be serialized with a timezone, regardless of host zone.
      final local = DateTime(2026, 9, 27, 10, 2);
      await AttendanceRepoImpl(client).createAttendance(
        employeeId: 'employee',
        date: DateTime(2026, 9, 27),
        status: 'present',
        checkIn: local,
      );
      expect(inserted!['check_in'], local.toUtc().toIso8601String());
      expect(inserted!['check_in'], endsWith('Z'));
    },
  );
  test(
    'Timezone repair requires explicit opt-in and uses a protected RPC',
    () async {
      final repairs = <Map>[];
      final client = await server((request) async {
        if (request.method == 'GET') {
          return [
            {'id': 'existing', 'employee_id': 'employee', 'date': '2026-09-27'},
          ];
        }
        expect(
          request.uri.path,
          '/rest/v1/rpc/repair_imported_attendance_timezone',
        );
        repairs.add(jsonDecode(await utf8.decoder.bind(request).join()) as Map);
        return 'repaired';
      }, role: 'hr');
      final repo = AttendanceRepoImpl(client);
      await repo.upsertAttendanceBatch([record()]);
      expect(repairs, isEmpty);
      await repo.upsertAttendanceBatch([record()], repairTimezone: true);
      expect(repairs.single, {
        'p_record_id': 'existing',
        'p_check_in': '2026-09-27T07:02:00.000Z',
        'p_check_out': '2026-09-27T13:43:00.000Z',
        'p_source_notes': 'Imported from biometric CSV (Person ID: 2)',
      });
    },
  );
  test(
    'Manual corrections also retain explicit timezone in their payload',
    () async {
      Map? inserted;
      final client = await server((request) async {
        expect(request.uri.path, '/rest/v1/approval_requests');
        inserted = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
        request.response.statusCode = 201;
        return null;
      }, role: 'hr');
      await AttendanceRepoImpl(client).createCorrectionRequest(
        recordId: 'record',
        employeeId: 'employee',
        date: DateTime(2026, 9, 27),
        proposedCheckIn: checkIn,
        proposedCheckOut: checkOut,
        reason: 'Fix time',
      );
      expect(
        inserted!['payload']['proposed_check_in'],
        '2026-09-27T07:02:00.000Z',
      );
      expect(
        inserted!['payload']['proposed_check_out'],
        '2026-09-27T13:43:00.000Z',
      );
    },
  );
}
