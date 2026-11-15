import 'dart:convert';
import 'dart:io';
import 'package:erp_sys/features/attendance/data/repos/employee_attendance_repo_impl.dart';
import 'package:erp_sys/features/approvals/data/repos/approvals_repo_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> row(int index, {String employee = 'employee'}) => {
  'id': 'record-$index',
  'tenant_id': 'tenant',
  'employee_id': employee,
  'date': '2026-10-05',
  'status': 'present',
  'check_in': '2026-10-05T05:00:00Z',
  'check_out': '2026-10-05T13:30:00Z',
  'created_at': '2026-10-05T05:00:00Z',
};
Future<SupabaseClient> server(
  Future<Object?> Function(HttpRequest) handler, {
  String role = 'employee',
  bool active = true,
  GotrueAsyncStorage? asyncStorage,
}) async {
  final listener = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  listener.listen((request) async {
    Object? data;
    if (request.uri.path == '/auth/v1/token') {
      final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
      final token =
          '${base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256'})))}.${base64Url.encode(utf8.encode(jsonEncode({'sub': 'auth-fixture', 'exp': exp})))}.test-signature';
      data = {
        'access_token': token,
        'refresh_token': 'test-refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': 'auth-fixture',
          'aud': 'authenticated',
          'email': 'fixture@example.test',
          'created_at': '2026-10-05T00:00:00Z',
        },
      };
    } else if (request.uri.path == '/rest/v1/users') {
      data = {
        'id': 'auth-fixture',
        'tenant_id': 'tenant',
        'email': 'fixture@example.test',
        'employee_id': 'employee',
        'role': role,
        'is_active': active,
      };
    } else {
      data = await handler(request);
    }
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(data));
    await request.response.close();
  });
  final client = SupabaseClient(
    'http://127.0.0.1:${listener.port}',
    'fixture-key',
    authOptions: AuthClientOptions(
      autoRefreshToken: false,
      pkceAsyncStorage: asyncStorage,
    ),
  );
  addTearDown(() async {
    await client.dispose();
    await listener.close(force: true);
  });
  await client.auth.signInWithPassword(
    email: 'fixture@example.test',
    password: 'fixture-password',
  );
  return client;
}

void main() {
  test('Monthly RPC returns scoped records and pending corrections', () async {
    final client = await server((request) async {
      expect(request.uri.path, '/rest/v1/rpc/employee_attendance_month');
      final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
      expect(body, {'p_month': '2026-10-01'});
      return {
        'records': [row(1)],
        'pending_record_ids': ['record-1'],
      };
    });
    final result = await EmployeeAttendanceRepoImpl(
      client,
    ).fetchMonth(employeeId: 'employee', month: DateTime(2026, 10, 20));
    expect(result.records.single.checkIn!.isUtc, isTrue);
    expect(result.pendingRecordIds, {'record-1'});
    expect(result.correctionsReady, isTrue);
  });
  test('Wrong employee response is rejected', () async {
    final client = await server(
      (_) async => {
        'records': [row(1, employee: 'foreign')],
        'pending_record_ids': [],
      },
    );
    await expectLater(
      EmployeeAttendanceRepoImpl(
        client,
      ).fetchMonth(employeeId: 'employee', month: DateTime(2026, 10)),
      throwsStateError,
    );
  });
  test(
    'Only missing RPC falls back to paginated month read; writes remain unavailable',
    () async {
      final offsets = <int>[];
      final client = await server((request) async {
        if (request.uri.path.contains('/rpc/')) {
          request.response.statusCode = 404;
          return {'code': 'PGRST202', 'message': 'Function not installed'};
        }
        expect(request.uri.path, '/rest/v1/attendance_records');
        expect(request.uri.queryParameters['employee_id'], 'eq.employee');
        expect(request.uri.queryParameters['tenant_id'], 'eq.tenant');
        expect(
          request.uri.queryParametersAll['date'],
          containsAll(['gte.2026-10-01', 'lt.2026-11-01']),
        );
        final offset = int.parse(request.uri.queryParameters['offset'] ?? '0');
        offsets.add(offset);
        return [
          for (var i = offset; i < (offset + 100).clamp(0, 101); i++) row(i),
        ];
      });
      final result = await EmployeeAttendanceRepoImpl(
        client,
      ).fetchMonth(employeeId: 'employee', month: DateTime(2026, 10));
      expect(offsets, [0, 100]);
      expect(result.records.length, 101);
      expect(result.correctionsReady, isFalse);
    },
  );
  test('Permission errors never fall back to legacy reads', () async {
    var requests = 0;
    final client = await server((request) async {
      requests++;
      request.response.statusCode = 403;
      return {'code': '42501', 'message': 'Forbidden'};
    });
    await expectLater(
      EmployeeAttendanceRepoImpl(
        client,
      ).fetchMonth(employeeId: 'employee', month: DateTime(2026, 10)),
      throwsA(isA<PostgrestException>()),
    );
    expect(requests, 1);
  });
  for (final role in ['manager', 'hr', 'admin']) {
    test(
      'Correction updates attendance only at final approval ($role)',
      () async {
        var attendanceUpdates = 0;
        final client = await server((request) async {
          if (request.uri.path == '/rest/v1/departments') return [];
          if (request.uri.path == '/rest/v1/employees') {
            return [
              {'id': 'subordinate'},
            ];
          }
          if (request.method == 'GET') {
            return {
              'employee_id': 'subordinate',
              'request_type': 'attendance_correction',
              'status': 'pending',
              'requested_by_role': 'employee',
              'current_approver_role': role,
              'payload': {
                'record_id': 'record-1',
                'proposed_check_in': '2026-10-05T06:00:00Z',
                'proposed_check_out': '2026-10-05T14:00:00Z',
              },
            };
          }
          final body =
              jsonDecode(await utf8.decoder.bind(request).join()) as Map;
          if (request.uri.path == '/rest/v1/attendance_records') {
            attendanceUpdates++;
            expect(request.uri.queryParameters['tenant_id'], 'eq.tenant');
            expect(body['check_in'], '2026-10-05T06:00:00Z');
          } else {
            expect(body['status'], role == 'admin' ? 'approved' : 'pending');
          }
          return null;
        }, role: role);
        await ApprovalsRepoImpl(client).approve('request-1');
        expect(attendanceUpdates, role == 'admin' ? 1 : 0);
      },
    );
  }
}
