part of 'employee_profile_details.dart';

class EmployeeContractVersion {
  const EmployeeContractVersion({
    required this.id,
    required this.contractType,
    this.startDate,
    this.endDate,
    this.probationMonths,
    this.fileUrl,
    this.createdAt,
  });

  final String id;
  final String contractType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? probationMonths;
  final String? fileUrl;
  final DateTime? createdAt;

  factory EmployeeContractVersion.fromMap(Map<String, dynamic> map) {
    return EmployeeContractVersion(
      id: map['id'].toString(),
      contractType: (map['contract_type'] ?? 'full_time').toString(),
      startDate: parseEmployeeProfileDate(map['start_date']),
      endDate: parseEmployeeProfileDate(map['end_date']),
      probationMonths: parseEmployeeProfileInt(map['probation_months']),
      fileUrl: map['file_url']?.toString(),
      createdAt: parseEmployeeProfileDate(map['created_at']),
    );
  }
}
