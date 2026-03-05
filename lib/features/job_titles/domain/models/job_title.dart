class JobTitle {
  const JobTitle({
    required this.id,
    required this.tenantId,
    required this.name,
    this.code,
    this.description,
    this.level,
    required this.isActive,
    required this.createdAt,
    this.departmentId,
  });

  final String id;
  final String tenantId;
  final String name;
  final String? code;
  final String? description;
  final int? level;
  final bool isActive;
  final DateTime createdAt;
  final String? departmentId;

  factory JobTitle.fromMap(Map<String, dynamic> map) {
    return JobTitle(
      id: map['id'].toString(),
      tenantId: map['tenant_id'].toString(),
      name: (map['name'] ?? '').toString(),
      code: map['code']?.toString(),
      description: map['description']?.toString(),
      level: map['level'] == null ? null : (map['level'] as num).toInt(),
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      departmentId: map['department_id']?.toString(),
    );
  }
}
