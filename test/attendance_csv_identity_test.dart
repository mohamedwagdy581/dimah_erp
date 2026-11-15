import 'dart:convert';
import 'package:erp_sys/features/attendance/data/repos/attendance_identity_repo_impl.dart';
import 'package:erp_sys/features/attendance/data/repos/attendance_repo_impl.dart';
import 'package:erp_sys/features/attendance/domain/models/attendance_import_record.dart';
import 'package:erp_sys/features/attendance/view/widgets/attendance_import_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'employee_attendance_repo_test.dart' show server;

const mappings = [
  {
    'id': 'erp-employee',
    'full_name': 'محمد وجدي',
    'device_employee_number': '2',
  },
];

void main() {
  test(
    'iVMS numeric dates and apostrophe Person IDs span September and October correctly',
    () {
      const csv =
          'Person ID,Name,Department,Time,Attendance Status,Attendance Check Point,Custom Name,Data Source\n'
          "'2,M.Wagdy,Dimah Music,9/27/2026 10:02,Check-in,Door1,Check In,Original Records\n"
          "'2,M.Wagdy,Dimah Music,9/27/2026 16:43,Check-out,Door1,Check Out,Original Records\n"
          "'2,M.Wagdy,Dimah Music,10/1/2026 9:53,Check-in,Door1,Check In,Original Records\n"
          "'2,M.Wagdy,Dimah Music,10/1/2026 10:13,Check-in,Door1,Check In,Original Records\n"
          "'2,M.Wagdy,Dimah Music,10/1/2026 17:04,Check-out,Door1,Check Out,Original Records\n"
          "'2,M.Wagdy,Dimah Music,10/5/2026 9:44,Check-in,Door1,Check In,Original Records";
      final rows = parseAttendanceCsvForPreview(csv, mappings);
      expect(rows.length, 3);
      expect(
        rows.every((row) => row['matched_employee_id'] == 'erp-employee'),
        true,
      );
      expect(rows[0]['date'], startsWith('2026-10-05'));
      expect(rows[0]['check_out'], isNull);
      expect(rows[1]['date'], startsWith('2026-10-01'));
      expect(rows[1]['check_in'], contains('T09:53:00'));
      expect(rows[1]['check_out'], contains('T17:04:00'));
      expect(rows[2]['date'], startsWith('2026-09-27'));
      expect(rows[2]['check_in'], contains('T10:02:00'));
      expect(rows[2]['check_out'], contains('T16:43:00'));
    },
  );
  test('iVMS split columns, seconds and 12-hour midnight are retained', () {
    final rows = parseAttendanceCsvForPreview(
      'Person ID,Name,Date,Time,Attendance Status\n'
      '2,Test,10/1/2026,12:03:09 AM,Check-in\n2,Test,10/1/2026,12:04:12 PM,Check-out',
      mappings,
    );
    expect(rows.single['check_in'], contains('T00:03:09'));
    expect(rows.single['check_out'], contains('T12:04:12'));
  });
  test('Invalid dates and times are not silently rolled into another day', () {
    for (final time in [
      '2/30/2026 10:02',
      '13/1/2026 10:02',
      '10/1/2026 25:02',
      '10/1/2026 10:60',
      '10/1/2026 0:10 PM',
      '2026-02-30 10:02',
    ]) {
      expect(
        parseAttendanceCsvForPreview(
          'Person ID,Name,Time,Attendance Status\n2,Test,$time,Check-in',
          mappings,
        ),
        isEmpty,
        reason: time,
      );
    }
  });
  test('Named-month exports still preserve date and seconds', () {
    final rows = parseAttendanceCsvForPreview(
      'Person ID,Name,Time,Attendance Status\n2,Test,4-Mar-26 13:46:07,Check-in',
      mappings,
    );
    expect(rows.single['date'], startsWith('2026-03-04'));
    expect(rows.single['check_in'], contains('T13:46:07'));
  });
  test('Saved Person ID matches despite completely different names', () {
    final rows = parseAttendanceCsvForPreview(
      '\uFEFFPerson ID,Name,Time,Attendance Status\n2,M.Wagdy,2026-02-01 10:07:09,Check-in\n2,M.Wagdy,2026-02-01 17:04:06,Check-out',
      mappings,
    );
    expect(rows.single['matched_employee_id'], 'erp-employee');
    expect(rows.single['date'], startsWith('2026-02-01'));
    expect(rows.single['late_minutes'], 0);
    expect(rows.single['overtime_minutes'], 0);
  });
  test('Matching names never override missing or different device number', () {
    final rows = parseAttendanceCsvForPreview(
      'Person ID,Name,Time,Attendance Status\n12,محمد وجدي,2026-02-01 10:07:09,Check-in',
      mappings,
    );
    expect(rows.single['matched_employee_id'], isNull);
  });
  test('Leading zeros in Person ID remain significant', () {
    final rows = parseAttendanceCsvForPreview(
      'Person ID,Name,Time,Attendance Status\n02,M.Wagdy,2026-02-01 10:07:09,Check-in',
      mappings,
    );
    expect(rows.single['matched_employee_id'], isNull);
  });
  test('Overtime is not mistaken for a normal check-in or check-out', () {
    final rows = parseAttendanceCsvForPreview(
      'Person ID,Name,Time,Attendance Status\n2,M.Wagdy,2026-02-02 10:00:13,Check-in\n2,M.Wagdy,2026-02-02 14:57:48,Overtime-In\n2,M.Wagdy,2026-02-02 22:04:06,Check-out\n2,M.Wagdy,2026-02-02 22:53:52,Overtime-Out',
      mappings,
    );
    expect(rows.single['check_in'], contains('T10:00:13'));
    expect(rows.single['check_out'], contains('T22:04:06'));
  });
  test('Missing name still matches by explicit Person ID', () {
    final rows = parseAttendanceCsvForPreview(
      'Person ID,Name,Time,Attendance Status\n2,,2026-02-01 10:07:09,Check-in',
      mappings,
    );
    expect(rows.single['matched_employee_id'], 'erp-employee');
  });
  test('Duplicate mapping and reversed times are rejected', () {
    const csv =
        'Person ID,Name,Time,Attendance Status\n2,M.Wagdy,2026-02-01 10:07:09,Check-in';
    expect(
      () => parseAttendanceCsvForPreview(csv, [...mappings, ...mappings]),
      throwsFormatException,
    );
    expect(
      () => parseAttendanceCsvForPreview(
        '$csv\n2,M.Wagdy,2026-02-01 09:00:00,Check-out',
        mappings,
      ),
      throwsFormatException,
    );
  });
  test(
    'Mapping list uses authenticated RPC, not employee names for lookup',
    () async {
      final client = await server((request) async {
        expect(
          request.uri.path,
          '/rest/v1/rpc/list_employee_attendance_identities',
        );
        return [
          {
            'employee_id': 'erp-employee',
            'full_name': 'محمد وجدي',
            'device_employee_number': '2',
          },
        ];
      }, role: 'hr');
      expect(await AttendanceIdentityRepoImpl(client).fetchAll(), mappings);
    },
  );
  test(
    'CSV import preserves existing day and never updates a correction',
    () async {
      final writes = <Map>[];
      final client = await server((request) async {
        expect(request.uri.path, '/rest/v1/attendance_records');
        if (request.method == 'GET') {
          return [
            {
              'id': 'existing-corrected',
              'employee_id': 'employee',
              'date': '2026-02-01',
            },
          ];
        }
        expect(request.method, 'POST');
        writes.add(jsonDecode(await utf8.decoder.bind(request).join()) as Map);
        request.response.statusCode = 201;
        return null;
      }, role: 'hr');
      AttendanceImportRecord record(int day) => AttendanceImportRecord(
        employeeId: 'employee',
        date: DateTime(2026, 2, day),
        status: 'present',
        checkIn: DateTime(2026, 2, day, 10),
        checkOut: DateTime(2026, 2, day, 17),
        notes: 'Imported',
      );
      await AttendanceRepoImpl(
        client,
      ).upsertAttendanceBatch([record(1), record(2), record(2)]);
      expect(writes.length, 1);
      expect(writes.single['date'], '2026-02-02');
    },
  );
}
