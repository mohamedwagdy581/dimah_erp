import '../models/job_title.dart';

abstract class JobTitlesRepo {
  /// Fetch paged job titles with search/filter/sort.
  Future<({List<JobTitle> items, int total})> fetchJobTitles({
    required int page,
    required int pageSize,
    String? search,
    bool? isActive,
    String? departmentId,
    String sortBy,
    bool ascending,
  });

  /// Create a new job title under current tenant.
  Future<void> createJobTitle({
    required String name,
    String? code,
    String? description,
    int? level,
  });

  /// Update an existing job title.
  Future<void> updateJobTitle({
    required String id,
    required String name,
    String? code,
    String? description,
    int? level,
    required bool isActive,
  });
}
