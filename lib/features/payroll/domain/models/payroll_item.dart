class PayrollItem {
  const PayrollItem({
    required this.id,
    required this.runId,
    required this.employeeId,
    required this.employeeName,
    required this.basicSalary,
    required this.housingAllowance,
    required this.transportAllowance,
    required this.otherAllowance,
    required this.total,
    this.jobTitle = '',
    this.photoUrl,
    this.employeeNumber,
  });

  final String id;
  final String runId;
  final String employeeId;
  final String employeeName;
  final String jobTitle;
  final String? photoUrl;
  final String? employeeNumber;
  final num basicSalary;
  final num housingAllowance;
  final num transportAllowance;
  final num otherAllowance;
  final num total;

  factory PayrollItem.fromMap(Map<String, dynamic> map) {
    final employee = map['employee'];
    return PayrollItem(
      id: map['id'].toString(),
      runId: map['run_id'].toString(),
      employeeId: map['employee_id'].toString(),
      employeeName: employee is Map
          ? (employee['full_name'] ?? '').toString()
          : '',
      jobTitle: employee is Map && employee['job_title'] is Map
          ? (employee['job_title']['name'] ?? '').toString()
          : '',
      photoUrl: employee is Map ? employee['photo_url']?.toString() : null,
      employeeNumber: employee is Map
          ? employee['employee_number']?.toString()
          : null,
      basicSalary: (map['basic_salary'] ?? 0) as num,
      housingAllowance: (map['housing_allowance'] ?? 0) as num,
      transportAllowance: (map['transport_allowance'] ?? 0) as num,
      otherAllowance: (map['other_allowance'] ?? 0) as num,
      total: (map['total_amount'] ?? 0) as num,
    );
  }
}
