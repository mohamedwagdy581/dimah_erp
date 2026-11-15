import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/features/accounting/accounts/data/repos/accounts_repo_impl.dart';
import 'package:erp_sys/features/accounting/journal/data/repos/journal_repo_impl.dart';
import 'package:erp_sys/features/accounting/journal/domain/models/journal_line.dart';
import 'employee_attendance_repo_test.dart' show server;

void main() {
  test(
    'Account update uses scoped server operation and saves active flag',
    () async {
      final client = await server((request) async {
        expect(request.uri.path, '/rest/v1/rpc/accounting_save_account');
        final body = jsonDecode(await utf8.decoder.bind(request).join());
        expect(body, {
          'p_id': 'account',
          'p_code': '5100',
          'p_name': 'Salary expenses',
          'p_type': 'expense',
          'p_is_active': false,
          'p_is_cash': false,
        });
        return 'account';
      }, role: 'accountant');
      await AccountsRepoImpl(client).updateAccount(
        id: 'account',
        code: ' 5100 ',
        name: ' Salary expenses ',
        type: 'expense',
        isActive: false,
      );
    },
  );
  test('Cash flag is sent for asset accounts', () async {
    final client = await server((request) async {
      final body = jsonDecode(await utf8.decoder.bind(request).join());
      expect(body['p_type'], 'asset');
      expect(body['p_is_cash'], true);
      return 'bank';
    }, role: 'accountant');
    await AccountsRepoImpl(client).updateAccount(
      id: 'bank',
      code: '1100',
      name: 'Bank',
      type: 'asset',
      isActive: true,
      isCash: true,
    );
  });
  test(
    'Draft retry uses the same single operation without partial writes',
    () async {
      final ids = <String>[];
      final client = await server((request) async {
        expect(request.uri.path, '/rest/v1/rpc/accounting_save_draft');
        final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
        ids.add(body['p_id'] as String);
        expect(body['p_date'], '2026-10-15');
        expect(body['p_memo'], 'Salary payment');
        expect(body['p_lines'], [
          {'account_id': 'expense', 'debit': 1000, 'credit': 0},
          {'account_id': 'bank', 'debit': 0, 'credit': 1000},
        ]);
        return body['p_id'];
      }, role: 'accountant');
      final repo = JournalRepoImpl(client);
      for (var i = 0; i < 2; i++) {
        await repo.createEntry(
          entryDate: DateTime(2026, 10, 15),
          memo: ' Salary payment ',
          requestId: 'request',
          lines: [
            const JournalLine(
              accountId: 'expense',
              accountName: 'Salary expenses',
              debit: 1000,
              credit: 0,
            ),
            const JournalLine(
              accountId: 'bank',
              accountName: 'Bank',
              debit: 0,
              credit: 1000,
            ),
          ],
        );
      }
      expect(ids, ['request', 'request']);
    },
  );
  test(
    'Account fetch applies tenant and active filters to rows and count',
    () async {
      var calls = 0;
      final client = await server((request) async {
        expect(request.uri.path, '/rest/v1/accounts');
        expect(request.uri.queryParameters['tenant_id'], 'eq.tenant');
        expect(request.uri.queryParameters['is_active'], 'eq.true');
        calls++;
        return [];
      }, role: 'accountant');
      await AccountsRepoImpl(
        client,
      ).fetchAccounts(page: 0, pageSize: 100, isActive: true);
      expect(calls, 2);
    },
  );
  test(
    'Draft service failure does not insert headers or lines separately',
    () async {
      var calls = 0;
      final client = await server((request) async {
        calls++;
        expect(request.uri.path, '/rest/v1/rpc/accounting_save_draft');
        request.response.statusCode = 403;
        return {'code': '42501', 'message': 'Accounting account required'};
      });
      await expectLater(
        JournalRepoImpl(
          client,
        ).createEntry(entryDate: DateTime(2026, 10, 15), memo: '', lines: []),
        throwsA(isA<Exception>()),
      );
      expect(calls, 1);
    },
  );
  test('Post entry calls accounting_post_entry with id', () async {
    final client = await server((request) async {
      expect(request.uri.path, '/rest/v1/rpc/accounting_post_entry');
      expect(jsonDecode(await utf8.decoder.bind(request).join()), {
        'p_id': 'entry',
      });
      return null;
    }, role: 'accountant');
    await JournalRepoImpl(client).postEntry('entry');
  });
}
