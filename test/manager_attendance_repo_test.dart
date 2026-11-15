import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/features/manager_attendance/manager_attendance_repo.dart';
import 'employee_attendance_repo_test.dart' show server;

void main() {
  test(
    'Monthly attendance is paginated and scoped to company and current team',
    () async {
      final offsets = <String>[];
      final client = await server((req) async {
        final q = req.uri.queryParameters;
        expect(q['tenant_id'], 'eq.tenant');
        switch (req.uri.path) {
          case '/rest/v1/departments':
            return [];
          case '/rest/v1/employees':
            expect(q['select'], contains('photo_url'));
            return [
              {'id': 'e1', 'full_name': 'Real member', 'photo_url': 'https://example.com/member.jpg'},
            ];
          case '/rest/v1/employee_tasks':
            return [];
          case '/rest/v1/approval_requests':
            return [];
          case '/rest/v1/attendance_records':
            expect(q['employee_id']?.replaceAll('"', ''), 'in.(e1)');
            expect(
              req.uri.queryParametersAll['date'],
              containsAll(['gte.2026-10-01', 'lt.2026-11-01']),
            );
            offsets.add(q['offset']!);
            final offset = int.parse(q['offset']!);
            return [
              for (var i = offset; i < (offset + 500).clamp(0, 501); i++)
                {
                  'id': '$i',
                  'tenant_id': 'tenant',
                  'employee_id': 'e1',
                  'date': '2026-10-05',
                  'status': 'present',
                },
            ];
          default:
            fail('Unexpected read ${req.uri}');
        }
      }, role: 'manager');
      final data = await SupabaseManagerAttendanceRepo(
        client,
      ).load(DateTime(2026, 10, 6));
      expect(data.records.length, 501);
      expect(offsets, ['0', '500']);
      expect(data.records.first.employeeName, 'Real member');
      expect(data.members.single.photoUrl, 'https://example.com/member.jpg');
    },
  );
  test('Empty team never issues an unscoped attendance query', () async {
    final client = await server((req) async {
      expect([
        '/rest/v1/departments',
        '/rest/v1/employees',
      ], contains(req.uri.path));
      return [];
    }, role: 'manager');
    expect(
      (await SupabaseManagerAttendanceRepo(
        client,
      ).load(DateTime(2026, 10))).records,
      isEmpty,
    );
  });
  test('Ordinary employee cannot load team attendance', () async {
    final client = await server((_) async => fail('Unexpected team read'));
    await expectLater(
      SupabaseManagerAttendanceRepo(client).load(DateTime(2026, 10)),
      throwsStateError,
    );
  });
}
