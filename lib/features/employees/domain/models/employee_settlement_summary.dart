class EmployeeSettlementSummary {
  const EmployeeSettlementSummary({
    required this.employeeId,
    this.employeeNumber,
    required this.fullName,
    this.photoUrl,
    required this.status,
    this.jobTitleName,
    this.hireDate,
    this.latestSettlementDate,
    required this.settlementsCount,
    this.latestNetAmount,
  });

  final String employeeId;
  final String? employeeNumber;
  final String fullName;
  final String? photoUrl;
  final String status;
  final String? jobTitleName;
  final DateTime? hireDate;
  final DateTime? latestSettlementDate;
  final int settlementsCount;
  final double? latestNetAmount;
}
