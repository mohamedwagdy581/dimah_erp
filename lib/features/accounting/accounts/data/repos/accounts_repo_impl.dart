import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/utils/request_id.dart';

import '../../domain/models/account.dart';
import '../../domain/repos/accounts_repo.dart';

class AccountsRepoImpl implements AccountsRepo {
  AccountsRepoImpl(this._client);
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

  @override
  Future<({List<Account> items, int total})> fetchAccounts({
    required int page,
    required int pageSize,
    String? search,
    String? type,
    bool? isActive,
    String sortBy = 'code',
    bool ascending = true,
  }) async {
    final tenantId = await _tenantId();
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final s = search?.trim();

    dynamic listQ = _client
        .from('accounts')
        .select(
          'id, tenant_id, code, name, type, is_active, is_cash, created_at',
        )
        .eq('tenant_id', tenantId);

    if (type != null && type.trim().isNotEmpty) {
      listQ = listQ.eq('type', type);
    }
    if (isActive != null) listQ = listQ.eq('is_active', isActive);

    if (s != null && s.isNotEmpty) {
      final escaped = s.replaceAll('%', r'\%').replaceAll('_', r'\_');
      listQ = listQ.or('name.ilike.%$escaped%,code.ilike.%$escaped%');
    }

    listQ = listQ.order(sortBy, ascending: ascending).range(from, to);

    final listRes = await listQ;
    final items = (listRes as List)
        .map((e) => Account.fromMap(e as Map<String, dynamic>))
        .toList();

    dynamic countQ = _client
        .from('accounts')
        .select('id')
        .eq('tenant_id', tenantId);

    if (type != null && type.trim().isNotEmpty) {
      countQ = countQ.eq('type', type);
    }
    if (isActive != null) countQ = countQ.eq('is_active', isActive);

    if (s != null && s.isNotEmpty) {
      final escaped = s.replaceAll('%', r'\%').replaceAll('_', r'\_');
      countQ = countQ.or('name.ilike.%$escaped%,code.ilike.%$escaped%');
    }

    final countRes = await countQ;
    final total = (countRes as List).length;

    return (items: items, total: total);
  }

  @override
  Future<void> createAccount({
    required String code,
    required String name,
    required String type,
    bool isActive = true,
    bool isCash = false,
  }) async {
    await updateAccount(
      id: newRequestId(),
      code: code,
      name: name,
      type: type,
      isActive: isActive,
      isCash: isCash,
    );
  }

  @override
  Future<void> updateAccount({
    required String id,
    required String code,
    required String name,
    required String type,
    required bool isActive,
    bool isCash = false,
  }) async {
    await _client.rpc(
      'accounting_save_account',
      params: {
        'p_id': id,
        'p_code': code.trim(),
        'p_name': name.trim(),
        'p_type': type,
        'p_is_active': isActive,
        'p_is_cash': isCash,
      },
    );
  }
}
