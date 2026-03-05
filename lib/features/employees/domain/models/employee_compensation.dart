class EmployeeCompensation {
  const EmployeeCompensation({
    required this.employeeId,
    required this.basicSalary,
    required this.housingAllowance,
    required this.transportAllowance,
    required this.otherAllowance,
  });

  final String employeeId;
  final num basicSalary;
  final num housingAllowance;
  final num transportAllowance;
  final num otherAllowance;

  num get total =>
      basicSalary + housingAllowance + transportAllowance + otherAllowance;

  factory EmployeeCompensation.fromMap(Map<String, dynamic> map) {
    return EmployeeCompensation(
      employeeId: map['employee_id'].toString(),
      basicSalary: (map['basic_salary'] ?? 0) as num,
      housingAllowance: (map['housing_allowance'] ?? 0) as num,
      transportAllowance: (map['transport_allowance'] ?? 0) as num,
      otherAllowance: (map['other_allowance'] ?? 0) as num,
    );
  }
}
