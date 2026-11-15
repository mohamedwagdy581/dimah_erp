part of 'employee_repo_impl.dart';

mixin _EmployeesRepoEmployeeCreateRpcMixin
    on _EmployeesRepoCreateFallbackMixin {
  Future<String?> _createEmployeeViaRpc({
    required String tenantId,
    required String fullName,
    required String email,
    required Map<String, dynamic> params,
  }) async {
    final res = await _client.rpc(
      'hr_create_employee_complete',
      params: params,
    );
    return employeeIdFromRpc(res);
  }
}
