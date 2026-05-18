part of 'employee_profile_details.dart';

class EmployeeSettlement {
  const EmployeeSettlement({
    required this.id,
    this.finalWorkingDate,
    this.settlementDate,
    required this.grossAmount,
    required this.deductionsAmount,
    this.notes,
    this.createdAt,
  });

  final String id;
  final DateTime? finalWorkingDate;
  final DateTime? settlementDate;
  final double grossAmount;
  final double deductionsAmount;
  final String? notes;
  final DateTime? createdAt;

  double get netAmount => grossAmount - deductionsAmount;

  factory EmployeeSettlement.fromMap(Map<String, dynamic> map) {
    return EmployeeSettlement(
      id: map['id']?.toString() ?? '',
      finalWorkingDate: parseEmployeeProfileDate(map['final_working_date']),
      settlementDate: parseEmployeeProfileDate(map['settlement_date']),
      grossAmount: parseEmployeeProfileDouble(map['gross_amount']) ?? 0,
      deductionsAmount:
          parseEmployeeProfileDouble(map['deductions_amount']) ?? 0,
      notes: map['notes']?.toString(),
      createdAt: parseEmployeeProfileDate(map['created_at']),
    );
  }
}
