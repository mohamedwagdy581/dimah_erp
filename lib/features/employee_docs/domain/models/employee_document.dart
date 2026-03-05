class EmployeeDocument {
  const EmployeeDocument({
    required this.id,
    required this.tenantId,
    required this.employeeId,
    required this.employeeName,
    required this.docType,
    required this.fileUrl,
    this.issuedAt,
    this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String tenantId;
  final String employeeId;
  final String employeeName;
  final String docType;
  final String fileUrl;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;

  factory EmployeeDocument.fromMap(Map<String, dynamic> map) {
    final employee = map['employee'];
    return EmployeeDocument(
      id: map['id'].toString(),
      tenantId: map['tenant_id'].toString(),
      employeeId: map['employee_id'].toString(),
      employeeName:
          employee is Map ? (employee['full_name'] ?? '').toString() : '',
      docType: (map['doc_type'] ?? 'contract').toString(),
      fileUrl: (map['file_url'] ?? '').toString(),
      issuedAt: map['issued_at'] == null
          ? null
          : DateTime.tryParse(map['issued_at'].toString()),
      expiresAt: map['expires_at'] == null
          ? null
          : DateTime.tryParse(map['expires_at'].toString()),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
