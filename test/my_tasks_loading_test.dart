import 'dart:convert';
import 'dart:io';

import 'package:erp_sys/features/employee_portal/data/repos/my_tasks_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  for (final loadAll in [false, true]) {
    test(
      'Task loading respects company/employee and pages data: loadAll=$loadAll',
      () async {
        // An isolated local HTTP fixture; no live Supabase requests.
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final client = SupabaseClient(
          'http://127.0.0.1:${server.port}',
          'test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
        addTearDown(() async {
          await client.dispose();
          await server.close(force: true);
        });
        final taskOffsets = <int>[];
        final logOffsets = <int>[];
        server.listen((request) async {
          Object response = [];
          final query = request.uri.queryParameters;
          final offset = int.tryParse(query['offset'] ?? '') ?? 0;
          final limit = int.tryParse(query['limit'] ?? '') ?? 1000;
          if (request.uri.path.endsWith('/token')) {
            final expires =
                DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
            String part(Map<String, dynamic> value) => base64UrlEncode(
              utf8.encode(jsonEncode(value)),
            ).replaceAll('=', '');
            response = {
              'access_token':
                  '${part({'alg': 'HS256'})}.${part({'sub': 'actor', 'exp': expires})}.signature',
              'refresh_token': 'fixture',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': 'actor',
                'aud': 'authenticated',
                'email': 'fixture@example.test',
                'created_at': '2026-10-04T00:00:00Z',
                'app_metadata': {},
                'user_metadata': {},
              },
            };
          } else if (request.uri.path.endsWith('/users')) {
            response = {'tenant_id': 'company'};
          } else {
            expect(query['tenant_id'], 'eq.company');
            if (request.uri.path.endsWith('/employee_tasks')) {
              expect(query['employee_id'], 'eq.employee');
              taskOffsets.add(offset);
              final rows = List.generate(
                501,
                (index) => <String, dynamic>{
                  'id': 't${index.toString().padLeft(3, '0')}',
                  'title': 'Fixture $index',
                  'status': 'todo',
                },
              );
              response = rows.skip(offset).take(limit).toList();
            } else if (request.uri.path.endsWith('/employee_task_time_logs')) {
              final includesFirst = (query['task_id'] ?? '').contains('t000');
              if (includesFirst) logOffsets.add(offset);
              response = includesFirst
                  ? List.generate(
                      501,
                      (_) => {'task_id': 't000', 'hours': 1},
                    ).skip(offset).take(limit).toList()
                  : [];
            } else if (request.uri.path.endsWith(
              '/employee_task_attachments',
            )) {
              response = (query['task_id'] ?? '').contains('t000')
                  ? [
                      {
                        'id': 'attachment',
                        'task_id': 't000',
                        'file_name': 'fixture.pdf',
                      },
                    ]
                  : [];
            }
          }
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode(response));
          await request.response.close();
        });
        await client.auth.signInWithPassword(
          email: 'fixture@example.test',
          password: 'fixture-password',
        );
        final records = await MyTasksRepo(
          client,
        ).loadTasks('employee', loadAll: loadAll);
        expect(records.length, loadAll ? 501 : 60);
        expect(taskOffsets, loadAll ? [0, 500] : [0]);
        expect(logOffsets, loadAll ? [0, 500] : [0]);
        expect(records.first['logged_hours'], 501.0);
        expect(records.first['time_log_count'], 501);
        expect(
          (records.first['attachments'] as List).single['file_name'],
          'fixture.pdf',
        );
      },
    );
  }
}
