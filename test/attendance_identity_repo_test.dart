import 'dart:convert';
import 'package:erp_sys/features/attendance/data/repos/attendance_identity_repo_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'employee_attendance_repo_test.dart' show server;

void main() {
  test('Identity RPCs preserve zeros, normalize input and scope employee', () async {
    final calls = <String>[];
    final client = await server((request) async {
      calls.add(request.uri.path);
      final body = jsonDecode(await utf8.decoder.bind(request).join());
      expect(body['p_employee_id'], 'employee');
      if (request.uri.path.endsWith('/get_employee_attendance_identity')) {
        return '0002';
      }
      expect(body['p_number'], '0002');
      return null;
    }, role: 'hr');
    final repo = AttendanceIdentityRepoImpl(client);
    expect(await repo.fetch('employee'), '0002');
    await repo.check(' ٠٠٠٢ ', employeeId: 'employee');
    await repo.save('employee', ' ٠٠٠٢ ');
    expect(calls.length, 3);
  });
  test('Preflight works before employee exists and unlink sends empty number', () async {
    final client = await server((request) async {
      final body = jsonDecode(await utf8.decoder.bind(request).join());
      if (request.uri.path.endsWith('/check_employee_attendance_identity')) {
        expect(body, {'p_employee_id': null, 'p_number': '02'});
      } else {
        expect(body, {'p_employee_id': 'employee', 'p_number': ''});
      }
      return null;
    });
    final repo = AttendanceIdentityRepoImpl(client);
    await repo.check('02');
    await repo.save('employee', ' ');
  });
  for (final code in ['PGRST202', '23505', '42501']) {
    test('RPC error $code never falls back to direct table writes', () async {
      var calls = 0;
      final client = await server((request) async {
        calls++;
        expect(request.uri.path, '/rest/v1/rpc/set_employee_attendance_identity');
        request.response.statusCode = 400;
        return {'code': code, 'message': 'Fixture error', 'details': null, 'hint': null};
      });
      final repo = AttendanceIdentityRepoImpl(client);
      await expectLater(repo.save('employee', '02'), throwsA(code == '42501' ? isA<PostgrestException>() : isA<StateError>()));
      expect(calls, 1);
    });
  }
}
