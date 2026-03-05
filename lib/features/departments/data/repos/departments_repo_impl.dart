// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repos/departments_repo.dart';
import '../../domain/models/department.dart';

class DepartmentsRepoImpl implements DepartmentsRepo {
  DepartmentsRepoImpl(this._client);
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
  Future<({List<Department> items, int total})> fetchDepartments({
    required int page,
    required int pageSize,
    String? search,
    bool? isActive,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    final tenantId = await _tenantId(); // عندك موجودة غالبًا
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final s = search?.trim();

    // ✅ استخدم dynamic لتفادي مشكلة اختلاف نوع الـ builder بين select/eq/or
    dynamic listQ = _client
        .from('departments')
        .select(
          'id, tenant_id, name, code, description, is_active, manager_id, created_at, '
          'manager:employees!departments_manager_employee_fk(full_name)',
        );

    // لازم فلتر tenant
    listQ = listQ.eq('tenant_id', tenantId);

    // فلتر is_active
    if (isActive != null) {
      listQ = listQ.eq('is_active', isActive);
    }

    // Search على name أو code (لاحظ: or بياخد String واحد فقط)
    if (s != null && s.isNotEmpty) {
      final escaped = s.replaceAll('%', r'\%').replaceAll('_', r'\_');
      listQ = listQ.or('name.ilike.%$escaped%,code.ilike.%$escaped%');
    }

    // ترتيب + pagination
    listQ = listQ.order(sortBy, ascending: ascending).range(from, to);

    final listRes = await listQ;
    final items = (listRes as List)
        .map((e) => Department.fromMap(e as Map<String, dynamic>))
        .toList();

    // ====== COUNT ======
    dynamic countQ = _client.from('departments').select('id');

    countQ = countQ.eq('tenant_id', tenantId);

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
  Future<void> createDepartment({
    required String name,
    String? code,
    String? description,
    String? managerId,
  }) async {
    final tenantId = await _tenantId();

    await _client.from('departments').insert({
      'tenant_id': tenantId,
      'name': name.trim(),
      'code': (code?.trim().isEmpty ?? true) ? null : code!.trim(),
      'description': (description?.trim().isEmpty ?? true)
          ? null
          : description!.trim(),
      // manager_id اختياري (لو موجود في الجدول)
      if (managerId != null && managerId.trim().isNotEmpty)
        'manager_id': managerId.trim(),
      'is_active': true,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateDepartment({
    required String id,
    required String name,
    String? code,
    String? description,
    String? managerId,
    required bool isActive,
  }) async {
    final tenantId = await _tenantId();

    await _client
        .from('departments')
        .update({
          'name': name.trim(),
          'code': (code?.trim().isEmpty ?? true) ? null : code!.trim(),
          'description': (description?.trim().isEmpty ?? true)
              ? null
              : description!.trim(),
          'manager_id': (managerId == null || managerId.trim().isEmpty)
              ? null
              : managerId.trim(),
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('tenant_id', tenantId)
        .eq('id', id);
  }

  @override
  Future<int> autoAssignManagers() async {
    final tenantId = await _tenantId();
    final res = await _client.rpc(
      'auto_assign_department_managers',
      params: {'p_tenant_id': tenantId},
    );
    if (res is int) return res;
    if (res is num) return res.toInt();
    return int.tryParse(res?.toString() ?? '0') ?? 0;
  }
}
