class Employee {
  const Employee({
    required this.id,
    required this.tenantId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.status,
    required this.hireDate,
    required this.createdAt,
    this.departmentId,
    this.jobTitleId,
    this.departmentName,
    this.jobTitleName,
  });

  final String id;
  final String tenantId;
  final String fullName;
  final String email;
  final String phone;
  final String status;
  final DateTime? hireDate;
  final DateTime createdAt;
  final String? departmentId;
  final String? jobTitleId;
  final String? departmentName;
  final String? jobTitleName;

  factory Employee.fromMap(Map<String, dynamic> map) {
    final department = map['department'];
    final jobTitle = map['job_title'];

    return Employee(
      id: map['id'].toString(),
      tenantId: map['tenant_id'].toString(),
      fullName: (map['full_name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      status: (map['status'] ?? 'active').toString(),
      hireDate: map['hire_date'] == null
          ? null
          : DateTime.tryParse(map['hire_date'].toString()),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      departmentId: map['department_id']?.toString(),
      jobTitleId: map['job_title_id']?.toString(),
      departmentName:
          department is Map ? department['name']?.toString() : null,
      jobTitleName: jobTitle is Map ? jobTitle['name']?.toString() : null,
    );
  }
}
