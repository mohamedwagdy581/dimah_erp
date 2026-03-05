import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/journal_entry.dart';
import '../../domain/models/journal_line.dart';
import '../../domain/repos/journal_repo.dart';

class JournalRepoImpl implements JournalRepo {
  JournalRepoImpl(this._client);
  final SupabaseClient _client;

  Future<String> _tenantId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final me = await _client
        .from('users')
        .select('tenant_id')
        .eq('id', uid)
        .single();

    final t = me['tenant_id'];
    if (t == null) throw Exception('Missing tenant_id for current user');
    return t.toString();
  }

  String _toDateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

  @override
  Future<({List<JournalEntry> items, int total})> fetchEntries({
    required int page,
    required int pageSize,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String sortBy = 'entry_date',
    bool ascending = false,
  }) async {
    final tenantId = await _tenantId();
    final from = page * pageSize;
    final to = from + pageSize - 1;

    dynamic listQ = _client
        .from('journal_entries')
        .select(
          'id, tenant_id, entry_date, memo, total_debit, total_credit, status, created_at',
        )
        .eq('tenant_id', tenantId);

    if (status != null && status.trim().isNotEmpty) {
      listQ = listQ.eq('status', status);
    }

    if (startDate != null) {
      listQ = listQ.gte('entry_date', _toDateOnly(startDate));
    }

    if (endDate != null) {
      listQ = listQ.lte('entry_date', _toDateOnly(endDate));
    }

    listQ = listQ.order(sortBy, ascending: ascending).range(from, to);

    final listRes = await listQ;
    final items = (listRes as List)
        .map((e) => JournalEntry.fromMap(e as Map<String, dynamic>))
        .toList();

    dynamic countQ = _client
        .from('journal_entries')
        .select('id')
        .eq('tenant_id', tenantId);

    if (status != null && status.trim().isNotEmpty) {
      countQ = countQ.eq('status', status);
    }

    if (startDate != null) {
      countQ = countQ.gte('entry_date', _toDateOnly(startDate));
    }

    if (endDate != null) {
      countQ = countQ.lte('entry_date', _toDateOnly(endDate));
    }

    final countRes = await countQ;
    final total = (countRes as List).length;

    return (items: items, total: total);
  }

  @override
  Future<void> createEntry({
    required DateTime entryDate,
    required String memo,
    required List<JournalLine> lines,
  }) async {
    final tenantId = await _tenantId();

    final totalDebit = lines.fold<num>(0, (s, l) => s + l.debit);
    final totalCredit = lines.fold<num>(0, (s, l) => s + l.credit);

    final entry = await _client
        .from('journal_entries')
        .insert({
          'tenant_id': tenantId,
          'entry_date': _toDateOnly(entryDate),
          'memo': memo.trim(),
          'total_debit': totalDebit,
          'total_credit': totalCredit,
          'status': 'draft',
        })
        .select('id')
        .single();

    final entryId = entry['id'].toString();

    final batch = lines
        .map(
          (l) => {
            'tenant_id': tenantId,
            'entry_id': entryId,
            'account_id': l.accountId,
            'debit': l.debit,
            'credit': l.credit,
          },
        )
        .toList();

    await _client.from('journal_lines').insert(batch);
  }
}
