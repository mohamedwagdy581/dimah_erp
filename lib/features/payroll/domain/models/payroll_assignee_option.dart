class PayrollAssigneeOption {
  const PayrollAssigneeOption({
    required this.employeeId,
    required this.fullName,
    this.employeeNumber,
    this.jobLevel,
  });

  final String employeeId;
  final String fullName;
  final String? employeeNumber;
  final String? jobLevel;
}
