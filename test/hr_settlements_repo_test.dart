import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/features/employees/data/repos/hr_settlements_repo.dart';
import 'package:erp_sys/features/employees/domain/models/hr_settlement.dart';
import 'employee_attendance_repo_test.dart' show server;

HrSettlementDraft _draft({
  SettlementAttachment? attachment,
  double gross = 1000,
  double deductions = 100,
}) => HrSettlementDraft(
  id: 'request-id',
  employeeId: 'employee',
  type: 'partial',
  date: DateTime(2026, 10, 26, 15),
  finalWorkingDate: DateTime(2026, 10, 26),
  gross: gross,
  deductions: deductions,
  notes: '  Original note  ',
  attachment: attachment,
);
void main() {
  test(
    'Loads every employee and settlement with tenant filtering and stable paging',
    () async {
      final pages = <String, List<int>>{};
      final client = await server((request) async {
        final path = request.uri.path;
        expect(request.uri.queryParameters['tenant_id'], 'eq.tenant');
        expect(request.uri.queryParameters['order'], contains('id'));
        final offset = int.parse(request.uri.queryParameters['offset'] ?? '0');
        pages.putIfAbsent(path, () => []).add(offset);
        final count = offset == 0 ? 500 : 1;
        if (path == '/rest/v1/employees') {
          return List.generate(
            count,
            (i) => {
              'id': 'employee-${offset + i}',
              'tenant_id': 'tenant',
              'full_name': 'Employee ${offset + i}',
              'status': 'active',
              'created_at': '2026-10-01',
            },
          );
        }
        expect(path, '/rest/v1/employee_settlements');
        return List.generate(
          count,
          (i) => {
            'id': 'settlement-${offset + i}',
            'employee_id': 'employee',
            'employee': {'full_name': 'Existing employee'},
            'gross_amount': 1000,
            'deductions_amount': 100,
            'settlement_date': '2026-10-20',
          },
        );
      }, role: 'hr');
      final result = await SupabaseHrSettlementsRepo(client).load();
      expect(result.employees.length, 501);
      expect(result.settlements.length, 501);
      expect(result.settlements.last.net, 900);
      expect(result.settlements.last.type, 'final');
      expect(pages.values, everyElement([0, 500]));
    },
  );
  test(
    'Save uses atomic RPC with preserved request ID and date-only values',
    () async {
      final calls = <Map>[];
      final client = await server((request) async {
        expect(request.uri.path, '/rest/v1/rpc/hr_save_employee_settlement');
        final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
        calls.add(body);
        return 'request-id';
      }, role: 'hr');
      final repo = SupabaseHrSettlementsRepo(client);
      await repo.save(_draft());
      await repo.save(_draft());
      expect(calls.length, 2);
      expect(calls.first, calls.last);
      expect(calls.first['p_id'], 'request-id');
      expect(calls.first['p_settlement_type'], 'partial');
      expect(calls.first['p_settlement_date'], '2026-10-26');
      expect(calls.first['p_gross_amount'], 1000);
      expect(calls.first['p_deductions_amount'], 100);
      expect(calls.first['p_notes'], 'Original note');
      expect(calls.first['p_attachment_path'], isNull);
    },
  );
  test(
    'Attachment upload precedes save and stays in tenant employee request path',
    () async {
      final calls = <String>[];
      final client = await server((request) async {
        if (request.uri.path.startsWith('/storage/v1/object/')) {
          calls.add('upload');
          expect(
            request.uri.path,
            '/storage/v1/object/employee_settlement_files/tenant/employee/request-id.pdf',
          );
          expect(request.headers.contentType!.mimeType, 'multipart/form-data');
          final upload = await utf8.decoder.bind(request).join();
          expect(upload, contains('application/pdf'));
          return {
            'Key': 'employee_settlement_files/tenant/employee/request-id.pdf',
          };
        }
        calls.add('save');
        expect(request.uri.path, '/rest/v1/rpc/hr_save_employee_settlement');
        final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
        expect(body['p_attachment_path'], 'tenant/employee/request-id.pdf');
        expect(body['p_attachment_name'], 'signed.pdf');
        return 'request-id';
      }, role: 'hr');
      await SupabaseHrSettlementsRepo(client).save(
        _draft(
          attachment: SettlementAttachment(
            name: 'signed.pdf',
            bytes: Uint8List.fromList([37, 80, 68, 70]),
          ),
        ),
      );
      expect(calls, ['upload', 'save']);
    },
  );
  test(
    'Unauthorized actor cannot read settlements or generate another tenant attachment link',
    () async {
      var calls = 0;
      final client = await server((request) async {
        calls++;
        return [];
      }, role: 'employee');
      final repo = SupabaseHrSettlementsRepo(client);
      await expectLater(repo.load(), throwsStateError);
      await expectLater(repo.attachmentUrl('other/file.pdf'), throwsStateError);
      expect(calls, 0);
    },
  );
  test('Invalid monetary values never reach save RPC', () async {
    var calls = 0;
    final client = await server((request) async {
      calls++;
      return [];
    }, role: 'hr');
    final repo = SupabaseHrSettlementsRepo(client);
    for (final draft in [
      _draft(gross: double.nan),
      _draft(gross: 0),
      _draft(deductions: -1),
      _draft(deductions: 1001),
    ]) {
      await expectLater(repo.save(draft), throwsArgumentError);
    }
    expect(calls, 0);
  });
}
