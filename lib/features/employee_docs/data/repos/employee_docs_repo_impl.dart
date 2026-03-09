import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/employee_document.dart';
import '../../domain/repos/employee_docs_repo.dart';

class EmployeeDocsRepoImpl implements EmployeeDocsRepo {
  EmployeeDocsRepoImpl(this._client);
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
  Future<({List<EmployeeDocument> items, int total})> fetchDocs({
    required int page,
    required int pageSize,
    String? search,
    String? employeeId,
    String? docType,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    final tenantId = await _tenantId();
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final s = search?.trim();

    dynamic listQ = _client
        .from('employee_documents')
        .select(
          'id, tenant_id, employee_id, doc_type, file_url, issued_at, expires_at, created_at, '
          'employee:employees(full_name)',
        )
        .eq('tenant_id', tenantId);

    if (employeeId != null && employeeId.isNotEmpty) {
      listQ = listQ.eq('employee_id', employeeId);
    }

    if (docType != null && docType.trim().isNotEmpty) {
      listQ = listQ.eq('doc_type', docType);
    }

    if (s != null && s.isNotEmpty) {
      final escaped = s.replaceAll('%', r'\%').replaceAll('_', r'\_');
      listQ = listQ.or('employee.full_name.ilike.%$escaped%');
    }

    final listRes = await listQ
        .order(sortBy, ascending: ascending)
        .range(from, to);

    final items = (listRes as List)
        .map((e) => EmployeeDocument.fromMap(e as Map<String, dynamic>))
        .toList();

    dynamic countQ = _client
        .from('employee_documents')
        .select('id')
        .eq('tenant_id', tenantId);

    if (employeeId != null && employeeId.isNotEmpty) {
      countQ = countQ.eq('employee_id', employeeId);
    }

    if (docType != null && docType.trim().isNotEmpty) {
      countQ = countQ.eq('doc_type', docType);
    }

    if (s != null && s.isNotEmpty) {
      final escaped = s.replaceAll('%', r'\%').replaceAll('_', r'\_');
      countQ = countQ.or('employee.full_name.ilike.%$escaped%');
    }

    final countRes = await countQ;
    final totalCount = (countRes as List).length;

    return (items: items, total: totalCount);
  }

  @override
  Future<void> createDoc({
    required String employeeId,
    required String docType,
    required String fileUrl,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) async {
    final tenantId = await _tenantId();

    await _client.from('employee_documents').insert({
      'tenant_id': tenantId,
      'employee_id': employeeId,
      'doc_type': docType,
      'file_url': fileUrl,
      'issued_at': issuedAt == null ? null : _toDateOnly(issuedAt),
      'expires_at': expiresAt == null ? null : _toDateOnly(expiresAt),
    });
  }
}
