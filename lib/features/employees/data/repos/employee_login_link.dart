/// The employee exists even if provisioning its login fails. Callers must not
/// fall back to creating another employee after this exception.
class EmployeeLoginLinkException implements Exception {
  const EmployeeLoginLinkException(this.employeeId, this.cause);
  final String employeeId;
  final Object cause;

  @override
  String toString() =>
      'تم حفظ الموظف ($employeeId)، لكن تعذّر ربط حساب الدخول. '
      'لا تضف الموظف مرة أخرى؛ أصلح ربط الحساب الموجود. التفاصيل: $cause';
}

Future<String> linkCreatedEmployee({
  required Object? rpcResponse,
  required Future<void> Function(String employeeId) linkLogin,
}) async {
  final employeeId = employeeIdFromRpc(rpcResponse);
  try {
    await linkLogin(employeeId);
  } catch (error) {
    throw EmployeeLoginLinkException(employeeId, error);
  }
  return employeeId;
}

String employeeIdFromRpc(Object? rpcResponse) {
  final String? employeeId = switch (rpcResponse) {
    String value => value.trim(),
    Map value => value['employee_id']?.toString().trim(),
    _ => null,
  };
  if (employeeId == null || employeeId.isEmpty) {
    throw const FormatException('Invalid employee creation RPC response');
  }
  return employeeId;
}
