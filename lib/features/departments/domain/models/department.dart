class Department {
  final String id;
  final String tenantId;
  final String name;
  final String? code;
  final String? description;
  final bool isActive;
  final String? managerId;
  final String? managerName;

  Department({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.code,
    required this.description,
    required this.isActive,
    this.managerId,
    this.managerName,
  });

  factory Department.fromMap(Map<String, dynamic> map) {
    final manager = map['manager'];
    return Department(
      id: map['id'].toString(),
      tenantId: map['tenant_id'].toString(),
      name: (map['name'] ?? '').toString(),
      code: map['code']?.toString(),
      description: map['description']?.toString(),
      isActive: (map['is_active'] ?? true) as bool,
      managerId: map['manager_id']?.toString(),
      managerName: manager is Map ? manager['full_name']?.toString() : null,
    );
  }
}
