class ApprovalRequest {
  const ApprovalRequest({
    required this.id,
    required this.tenantId,
    required this.requestType,
    required this.employeeId,
    required this.employeeName,
    required this.status,
    required this.createdAt,
    this.rejectReason,
    this.payload,
    this.requestedByRole,
    this.currentApproverRole,
  });

  final String id;
  final String tenantId;
  final String requestType; // e.g. leave / attendance_correction
  final String employeeId;
  final String employeeName;
  final String status; // pending/approved/rejected
  final DateTime createdAt;
  final String? rejectReason;
  final Map<String, dynamic>? payload;
  final String? requestedByRole;
  final String? currentApproverRole;

  factory ApprovalRequest.fromMap(Map<String, dynamic> map) {
    final employee = map['employee'];
    return ApprovalRequest(
      id: map['id'].toString(),
      tenantId: map['tenant_id'].toString(),
      requestType: (map['request_type'] ?? '').toString(),
      employeeId: map['employee_id'].toString(),
      employeeName:
          employee is Map ? (employee['full_name'] ?? '').toString() : '',
      status: (map['status'] ?? 'pending').toString(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      rejectReason: map['reject_reason']?.toString(),
      payload: map['payload'] is Map
          ? Map<String, dynamic>.from(map['payload'] as Map)
          : null,
      requestedByRole: map['requested_by_role']?.toString(),
      currentApproverRole: map['current_approver_role']?.toString(),
    );
  }
}
