import '../models/employee_document.dart';

abstract class EmployeeDocsRepo {
  Future<({List<EmployeeDocument> items, int total})> fetchDocs({
    required int page,
    required int pageSize,
    String? search,
    String? docType,
    String sortBy,
    bool ascending,
  });

  Future<void> createDoc({
    required String employeeId,
    required String docType,
    required String fileUrl,
    DateTime? issuedAt,
    DateTime? expiresAt,
  });
}
