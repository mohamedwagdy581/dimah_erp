class Account {
  const Account({
    required this.id,
    required this.tenantId,
    required this.code,
    required this.name,
    required this.type,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String tenantId;
  final String code;
  final String name;
  final String type; // asset / liability / equity / income / expense
  final bool isActive;
  final DateTime createdAt;

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'].toString(),
      tenantId: map['tenant_id'].toString(),
      code: (map['code'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      type: (map['type'] ?? 'expense').toString(),
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
