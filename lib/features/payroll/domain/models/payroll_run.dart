class PayrollRun {
  const PayrollRun({
    required this.id,
    required this.tenantId,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    required this.totalEmployees,
    required this.totalAmount,
    required this.createdAt,
    this.rejectReason,
    this.disbursementStatus,
    this.disbursementTaskId,
    this.disbursementAssigneeEmployeeId,
    this.hrApprovedAt,
    this.financeManagerApprovedAt,
    this.adminApprovedAt,
  });

  final String id;
  final String tenantId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String status;
  final int totalEmployees;
  final num totalAmount;
  final DateTime createdAt;
  final String? rejectReason;
  final String? disbursementStatus;
  final String? disbursementTaskId;
  final String? disbursementAssigneeEmployeeId;
  final DateTime? hrApprovedAt;
  final DateTime? financeManagerApprovedAt;
  final DateTime? adminApprovedAt;

  factory PayrollRun.fromMap(Map<String, dynamic> map) {
    return PayrollRun(
      id: map['id'].toString(),
      tenantId: map['tenant_id'].toString(),
      periodStart: DateTime.parse(map['period_start'].toString()),
      periodEnd: DateTime.parse(map['period_end'].toString()),
      status: (map['status'] ?? 'draft').toString(),
      totalEmployees:
          map['total_employees'] == null ? 0 : (map['total_employees'] as num).toInt(),
      totalAmount: (map['total_amount'] ?? 0) as num,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      rejectReason: map['reject_reason']?.toString(),
      disbursementStatus: map['disbursement_status']?.toString(),
      disbursementTaskId: map['disbursement_task_id']?.toString(),
      disbursementAssigneeEmployeeId: map['disbursement_assignee_employee_id']?.toString(),
      hrApprovedAt: DateTime.tryParse(map['hr_approved_at']?.toString() ?? ''),
      financeManagerApprovedAt: DateTime.tryParse(
        map['finance_manager_approved_at']?.toString() ?? '',
      ),
      adminApprovedAt: DateTime.tryParse(map['admin_approved_at']?.toString() ?? ''),
    );
  }
}
