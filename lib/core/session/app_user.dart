class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.tenantId,
    required this.employeeId,
  });

  final String id;
  final String email;
  final String role;
  final String tenantId;
  final String? employeeId;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: (json['role'] ?? 'employee') as String,
      tenantId: json['tenant_id'] as String,
      employeeId: json['employee_id'] as String?,
    );
  }
}
