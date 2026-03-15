part of 'employee_repo_impl.dart';

mixin _EmployeesRepoEmployeeCreateRpcMixin on _EmployeesRepoCreateFallbackMixin {
  Future<String?> _createEmployeeViaRpc({
    required String tenantId,
    required String fullName,
    required String email,
    required Map<String, dynamic> params,
  }) async {
    final res = await _client.rpc('create_employee_with_comp', params: params);
    if (res is String) return res;
    if (res is Map && res['employee_id'] != null) {
      final empId = res['employee_id'].toString();
      await _createAndLinkTestLogin(
        tenantId: tenantId,
        employeeId: empId,
        fullName: fullName,
        email: email,
      );
      return empId;
    }
    throw Exception('Invalid RPC response');
  }
}
