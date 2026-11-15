import 'dart:convert';
import 'dart:typed_data';
import 'package:erp_sys/features/dashboard/data/manager_task_attachment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'Attachment validation rejects oversized, empty and unsupported files',
    () {
      expect(ManagerTaskAttachment.accepts('Brief.PDF', 100), isTrue);
      expect(
        ManagerTaskAttachment.accepts(
          'files.zip',
          ManagerTaskAttachment.maxBytes,
        ),
        isTrue,
      );
      expect(
        ManagerTaskAttachment.accepts(
          'brief.pdf',
          ManagerTaskAttachment.maxBytes + 1,
        ),
        isFalse,
      );
      expect(ManagerTaskAttachment.accepts('brief.pdf', 0), isFalse);
      expect(ManagerTaskAttachment.accepts('program.exe', 10), isFalse);
    },
  );
  test(
    'Upload failure retries the saved task without creating another task',
    () async {
      final submission = ManagerTaskSubmission();
      var creates = 0, attempts = 0;
      Future<String> create() async {
        creates++;
        return 'task-1';
      }

      Future<void> attach(String id) async {
        expect(id, 'task-1');
        attempts++;
        if (attempts == 1) throw StateError('upload failed');
      }

      await expectLater(
        submission.submit(create: create, attach: attach),
        throwsStateError,
      );
      expect(submission.taskId, 'task-1');
      await submission.submit(create: create, attach: attach);
      expect(creates, 1);
      expect(attempts, 2);
      submission.clear();
      expect(submission.taskId, isNull);
    },
  );
  test('Create failure leaves no saved task to attach', () async {
    final submission = ManagerTaskSubmission();
    var uploads = 0;
    await expectLater(
      submission.submit(
        create: () async => throw StateError('insert failed'),
        attach: (_) async {
          uploads++;
        },
      ),
      throwsStateError,
    );
    expect(uploads, 0);
    expect(submission.taskId, isNull);
  });
  test(
    'Metadata failure retries same uploaded object and preserves original name',
    () async {
      var uploads = 0, inserts = 0;
      var metadataSaved = false;
      final paths = <String>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        httpClient: MockClient((request) async {
          if (request.url.path.contains('/storage/v1/object/')) {
            uploads++;
            paths.add(request.url.path);
            return uploads == 1
                ? http.Response('{"Key":"stored"}', 200, request: request)
                : http.Response(
                    '{"statusCode":"409","error":"Duplicate","message":"The resource already exists"}',
                    409,
                    request: request,
                  );
          }
          if (request.method == 'GET') {
            expect(request.url.queryParameters['tenant_id'], 'eq.tenant-1');
            expect(request.url.queryParameters['task_id'], 'eq.task-1');
            return http.Response(
              metadataSaved ? '[{"id":"attachment-1"}]' : '[]',
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          inserts++;
          final row = jsonDecode(request.body) as Map<String, dynamic>;
          expect(row['file_name'], 'شرح المهمة.pdf');
          expect(row['uploaded_by_user_id'], 'user-1');
          expect(row['mime_type'], 'application/pdf');
          if (inserts == 1) {
            return http.Response(
              '{"message":"temporarily unavailable"}',
              503,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          metadataSaved = true;
          return http.Response(
            '',
            201,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final file = ManagerTaskAttachment(
        name: 'شرح المهمة.pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'application/pdf',
      );
      Future<bool> upload() => file.upload(
        client,
        tenantId: 'tenant-1',
        taskId: 'task-1',
        userId: 'user-1',
      );
      await expectLater(upload(), throwsA(isA<PostgrestException>()));
      expect(await upload(), isTrue);
      expect(paths.toSet().length, 1);
      expect(await upload(), isFalse);
      expect(uploads, 2);
      expect(inserts, 2);
    },
  );
}
