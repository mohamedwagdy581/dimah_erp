import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/features/hr_home/hr_home_repo.dart';
import 'employee_attendance_repo_test.dart' show server;

void main() {
  test(
    'HR reads company scope, all pages, month and recorded weekly exceptions',
    () async {
      final offsets = <String>[];
      final client = await server((req) async {
        final q = req.uri.queryParameters;
        expect(q['tenant_id'], 'eq.tenant');
        switch (req.uri.path) {
          case '/rest/v1/employees':
            offsets.add(q['offset']!);
            if (q['offset'] == '0') {
              return List.generate(
                500,
                (i) => {'id': '$i', 'hire_date': '2026-09-01'},
              );
            }
            return [
              {'id': '500', 'hire_date': '2026-10-05'},
            ];
          case '/rest/v1/attendance_records':
            expect(
              req.uri.queryParametersAll['date'],
              containsAll(['gte.2026-10-04', 'lte.2026-10-06']),
            );
            expect(q['status']?.replaceAll('"', ''), 'in.(late,absent)');
            return [
              {'id': 'late'},
            ];
          case '/rest/v1/employee_documents':
            expect(q['expires_at'], isNotNull);
            return [
              {
                'id': 'document',
                'doc_type': 'id_card',
                'expires_at': '2026-10-08',
              },
            ];
          case '/rest/v1/approval_requests':
            expect(q['status'], 'eq.pending');
            expect(q['request_type'], 'eq.leave');
            return [];
          default:
            fail('Unexpected read');
        }
      }, role: 'hr');
      final result = await SupabaseHrHomeRepo(
        client,
      ).load(DateTime(2026, 10, 6));
      expect(result.employees, 501);
      expect(result.newEmployees, 1);
      expect(result.attendanceIssues, 1);
      expect(offsets, ['0', '500']);
    },
  );
  test('Employee cannot load company HR data', () async {
    final client = await server((_) async => fail('Unauthorized read'));
    await expectLater(
      SupabaseHrHomeRepo(client).load(DateTime(2026, 10, 6)),
      throwsStateError,
    );
  });
}
