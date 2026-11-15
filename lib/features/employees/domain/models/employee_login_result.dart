class EmployeeLoginResult {
  const EmployeeLoginResult({
    required this.employeeId,
    required this.email,
    required this.role,
    required this.accountCreated,
  });
  final String employeeId;
  final String email;
  final String role;
  final bool accountCreated;

  factory EmployeeLoginResult.fromMap(Map<String, dynamic> data) {
    if (data['employeeId'] is! String ||
        data['email'] is! String ||
        !['employee', 'manager'].contains(data['role']) ||
        data['accountCreated'] is! bool) {
      throw const FormatException('Invalid login provisioning result');
    }
    return EmployeeLoginResult(
      employeeId: data['employeeId'] as String,
      email: data['email'] as String,
      role: data['role'] as String,
      accountCreated: data['accountCreated'] as bool,
    );
  }
}

bool isValidEmployeeLoginPassword(String value) =>
    value.length >= 12 &&
    RegExp(r'[A-Z]').hasMatch(value) &&
    RegExp(r'[a-z]').hasMatch(value) &&
    RegExp(r'[0-9]').hasMatch(value) &&
    RegExp(r'[^A-Za-z0-9]').hasMatch(value);
