import '../models/department.dart';

/// Domain contract (لا يعرف Supabase)
abstract class DepartmentsRepo {
  /// Returns paged departments + total rows (for pagination UI).
  Future<({List<Department> items, int total})> fetchDepartments({
    required int page, // zero-based
    required int pageSize,
    String? search, // search in name/code
    bool? isActive, // null = all
    String sortBy, // 'created_at' or 'name'
    bool ascending,
  });

  Future<void> createDepartment({
    required String name,
    String? code,
    String? description,
    String? managerId, // optional
  });

  Future<void> updateDepartment({
    required String id,
    required String name,
    String? code,
    String? description,
    String? managerId, // optional
    required bool isActive,
  });

  Future<int> autoAssignManagers();
}
