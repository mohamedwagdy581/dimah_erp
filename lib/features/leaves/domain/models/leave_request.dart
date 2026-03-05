class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.tenantId,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.fileUrl,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String tenantId;
  final String employeeId;
  final String employeeName;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String? fileUrl;
  final String? notes;
  final DateTime createdAt;

  factory LeaveRequest.fromMap(Map<String, dynamic> map) {
    final employee = map['employee'];
    return LeaveRequest(
      id: map['id'].toString(),
      tenantId: map['tenant_id'].toString(),
      employeeId: map['employee_id'].toString(),
      employeeName:
          employee is Map ? (employee['full_name'] ?? '').toString() : '',
      type: (map['type'] ?? 'annual').toString(),
      startDate: DateTime.parse(map['start_date'].toString()),
      endDate: DateTime.parse(map['end_date'].toString()),
      status: (map['status'] ?? 'pending').toString(),
      fileUrl: map['file_url']?.toString(),
      notes: map['notes']?.toString(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
