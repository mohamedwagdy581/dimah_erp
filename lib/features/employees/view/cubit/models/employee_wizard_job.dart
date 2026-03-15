import 'package:equatable/equatable.dart';

class EmployeeWizardJob extends Equatable {
  const EmployeeWizardJob({
    this.departmentId,
    this.managerId,
    this.jobTitleId,
    this.hireDate,
    this.employmentType = 'full_time',
    this.contractType = 'full_time',
    this.contractStart,
    this.contractEnd,
    this.probationMonths,
    this.contractFileUrl = '',
  });

  final String? departmentId;
  final String? managerId;
  final String? jobTitleId;
  final DateTime? hireDate;
  final String employmentType;
  final String contractType;
  final DateTime? contractStart;
  final DateTime? contractEnd;
  final int? probationMonths;
  final String contractFileUrl;

  EmployeeWizardJob copyWith({
    String? departmentId,
    String? managerId,
    String? jobTitleId,
    DateTime? hireDate,
    String? employmentType,
    String? contractType,
    DateTime? contractStart,
    DateTime? contractEnd,
    int? probationMonths,
    String? contractFileUrl,
  }) {
    return EmployeeWizardJob(
      departmentId: departmentId ?? this.departmentId,
      managerId: managerId ?? this.managerId,
      jobTitleId: jobTitleId ?? this.jobTitleId,
      hireDate: hireDate ?? this.hireDate,
      employmentType: employmentType ?? this.employmentType,
      contractType: contractType ?? this.contractType,
      contractStart: contractStart ?? this.contractStart,
      contractEnd: contractEnd ?? this.contractEnd,
      probationMonths: probationMonths ?? this.probationMonths,
      contractFileUrl: contractFileUrl ?? this.contractFileUrl,
    );
  }

  @override
  List<Object?> get props => [
    departmentId,
    managerId,
    jobTitleId,
    hireDate,
    employmentType,
    contractType,
    contractStart,
    contractEnd,
    probationMonths,
    contractFileUrl,
  ];
}
