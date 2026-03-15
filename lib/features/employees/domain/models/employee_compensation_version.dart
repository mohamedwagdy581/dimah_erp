part of 'employee_profile_details.dart';

class EmployeeCompensationVersion {
  const EmployeeCompensationVersion({
    required this.id,
    required this.basicSalary,
    required this.housingAllowance,
    required this.transportAllowance,
    required this.otherAllowance,
    this.effectiveAt,
    this.note,
    this.createdAt,
  });

  final String id;
  final double basicSalary;
  final double housingAllowance;
  final double transportAllowance;
  final double otherAllowance;
  final DateTime? effectiveAt;
  final String? note;
  final DateTime? createdAt;

  double get total =>
      basicSalary + housingAllowance + transportAllowance + otherAllowance;

  factory EmployeeCompensationVersion.fromMap(Map<String, dynamic> map) {
    return EmployeeCompensationVersion(
      id: map['id'].toString(),
      basicSalary: parseEmployeeProfileDouble(map['basic_salary']) ?? 0,
      housingAllowance:
          parseEmployeeProfileDouble(map['housing_allowance']) ?? 0,
      transportAllowance:
          parseEmployeeProfileDouble(map['transport_allowance']) ?? 0,
      otherAllowance: parseEmployeeProfileDouble(map['other_allowance']) ?? 0,
      effectiveAt: parseEmployeeProfileDate(map['effective_at']),
      note: map['note']?.toString(),
      createdAt: parseEmployeeProfileDate(map['created_at']),
    );
  }
}
