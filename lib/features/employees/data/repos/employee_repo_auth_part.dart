part of 'employee_repo_impl.dart';

mixin _EmployeesRepoAuthMixin on _EmployeesRepoSessionMixin {
  Future<void> checkEmployeeCreationReady() async {
    try {
      final response = await _client.functions.invoke(
        'provision-employee-login',
        body: {'action': 'check'},
      );
      if (response.data is! Map ||
          response.data['ready'] != true ||
          response.data['version'] != 2) {
        throw const FormatException(
          'Employee provisioning service needs updating',
        );
      }
    } on FunctionException catch (error) {
      if (error.details is Map && error.details['code'] == 'invalid_employee') {
        throw StateError(
          'خدمة provision-employee-login قديمة. حدّثها من ملف النشر قبل إضافة الموظف.',
        );
      }
      throw Exception(
        error.details is Map
            ? error.details['message'] ??
                  'خدمة حسابات الموظفين تحتاج التفعيل قبل الإضافة.'
            : 'خدمة حسابات الموظفين تحتاج التفعيل قبل الإضافة.',
      );
    }
  }

  Future<EmployeeLoginResult> provisionEmployeeLogin({
    required String employeeId,
    required String role,
    required String initialPassword,
  }) async {
    if (!['employee', 'manager'].contains(role)) {
      throw ArgumentError('Unsupported employee login role');
    }
    try {
      final response = await _client.functions.invoke(
        'provision-employee-login',
        body: {
          'employeeId': employeeId,
          'role': role,
          'initialPassword': initialPassword,
        },
      );
      final result = EmployeeLoginResult.fromMap(
        Map<String, dynamic>.from(response.data as Map),
      );
      if (result.employeeId != employeeId || result.role != role) {
        throw const FormatException('Login response does not match employee');
      }
      return result;
    } on FunctionException catch (error) {
      final details = error.details;
      final message = details is Map ? details['message']?.toString() : null;
      throw Exception(message ?? 'تعذّر تجهيز حساب الدخول؛ أعد المحاولة');
    }
  }
}
