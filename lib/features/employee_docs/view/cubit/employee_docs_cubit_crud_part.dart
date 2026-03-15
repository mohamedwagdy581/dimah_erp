part of 'employee_docs_cubit.dart';

extension EmployeeDocsCubitCrudX on EmployeeDocsCubit {
  Future<void> createEmployeeDoc({
    required String employeeId,
    required String docType,
    required String fileUrl,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) async {
    await _repo.createDoc(
      employeeId: employeeId,
      docType: docType,
      fileUrl: fileUrl,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );
    await loadSingleEmployeeDocs(employeeId);
  }

  Future<void> updateEmployeeDoc({
    required String id,
    required String employeeId,
    required String docType,
    required String fileUrl,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) async {
    await _repo.updateDoc(
      id: id,
      employeeId: employeeId,
      docType: docType,
      fileUrl: fileUrl,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );
    await loadSingleEmployeeDocs(employeeId);
  }

  Future<void> deleteEmployeeDoc({
    required String id,
    required String employeeId,
    required String fileUrl,
  }) async {
    await _repo.deleteDoc(id: id, fileUrl: fileUrl);
    await loadSingleEmployeeDocs(employeeId);
  }
}
