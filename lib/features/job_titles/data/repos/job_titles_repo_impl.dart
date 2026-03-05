import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/job_title.dart';
import '../../domain/repos/job_titles_repo.dart';

class JobTitlesRepoImpl implements JobTitlesRepo {
  JobTitlesRepoImpl(this._client);

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
  Future<({List<JobTitle> items, int total})> fetchJobTitles({
    required int page,
    required int pageSize,
    String? search,
    bool? isActive,
    String? departmentId,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    final tenantId = await _tenantId();
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final s = search?.trim();

    // ===== List query =====
    dynamic listQ = _client
        .from('job_titles')
        .select(
          'id, tenant_id, name, code, description, level, department_id, is_active, created_at',
        )
        .eq('tenant_id', tenantId);

    if (departmentId != null) {
      listQ = listQ.eq('department_id', departmentId);
    }

    if (isActive != null) {
      listQ = listQ.eq('is_active', isActive);
    }

    if (s != null && s.isNotEmpty) {
      final escaped = s.replaceAll('%', r'\%').replaceAll('_', r'\_');
      listQ = listQ.or('name.ilike.%$escaped%,code.ilike.%$escaped%');
    }

    listQ = listQ.order(sortBy, ascending: ascending).range(from, to);

    final listRes = await listQ;
    final items = (listRes as List)
        .map((e) => JobTitle.fromMap(e as Map<String, dynamic>))
        .toList();

    // ===== Count query =====
    dynamic countQ = _client.from('job_titles').select('id');

    if (departmentId != null) {
      countQ = countQ.eq('department_id', departmentId);
    }

    if (isActive != null) {
      countQ = countQ.eq('is_active', isActive);
    }

    if (s != null && s.isNotEmpty) {
      final escaped = s.replaceAll('%', r'\%').replaceAll('_', r'\_');
      countQ = countQ.or('name.ilike.%$escaped%,code.ilike.%$escaped%');
    }

    final countRes = await countQ;
    final total = (countRes as List).length;

    return (items: items, total: total);
  }

  @override
  Future<void> createJobTitle({
    required String name,
    String? code,
    String? description,
    int? level,
    String? departmentId,
  }) async {
    final tenantId = await _tenantId();

    await _client.from('job_titles').insert({
      'tenant_id': tenantId,
      'name': name.trim(),
      'code': code?.trim().isEmpty == true ? null : code?.trim(),
      'description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      'level': level,
      'department_id': (departmentId != null && departmentId.trim().isNotEmpty)
          ? departmentId.trim()
          : null,
      'is_active': true,
    });
  }

  @override
  Future<void> updateJobTitle({
    required String id,
    required String name,
    String? code,
    String? description,
    int? level,
    String? departmentId,
    required bool isActive,
  }) async {
    final tenantId = await _tenantId();

    await _client
        .from('job_titles')
        .update({
          'name': name.trim(),
          'code': code?.trim().isEmpty == true ? null : code?.trim(),
          'description': description?.trim().isEmpty == true
              ? null
              : description?.trim(),
          'level': level,
          'department_id':
              (departmentId != null && departmentId.trim().isNotEmpty)
              ? departmentId.trim()
              : null,
          'is_active': isActive,
        })
        .eq('tenant_id', tenantId)
        .eq('id', id);
  }
}
