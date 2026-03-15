import 'package:equatable/equatable.dart';

import 'models/employee_wizard_additional.dart';
import 'models/employee_wizard_compensation.dart';
import 'models/employee_wizard_job.dart';
import 'models/employee_wizard_personal.dart';

class EmployeeWizardState extends Equatable {
  const EmployeeWizardState({
    this.personal = const EmployeeWizardPersonal(),
    this.job = const EmployeeWizardJob(),
    this.compensation = const EmployeeWizardCompensation(),
    this.additional = const EmployeeWizardAdditional(),
    this.loading = false,
    this.success = false,
    this.error,
  });

  final EmployeeWizardPersonal personal;
  final EmployeeWizardJob job;
  final EmployeeWizardCompensation compensation;
  final EmployeeWizardAdditional additional;
  final bool loading;
  final bool success;
  final String? error;

  EmployeeWizardState copyWith({
    EmployeeWizardPersonal? personal,
    EmployeeWizardJob? job,
    EmployeeWizardCompensation? compensation,
    EmployeeWizardAdditional? additional,
    bool? loading,
    bool? success,
    String? error,
  }) {
    return EmployeeWizardState(
      personal: personal ?? this.personal,
      job: job ?? this.job,
      compensation: compensation ?? this.compensation,
      additional: additional ?? this.additional,
      loading: loading ?? this.loading,
      success: success ?? this.success,
      error: error,
    );
  }

  String get employeeNumber => personal.employeeNumber;
  String get fullName => personal.fullName;
  String get email => personal.email;
  String get phone => personal.phone;
  String get photoUrl => personal.photoUrl;
  String get nationalId => personal.nationalId;
  String? get gender => personal.gender;
  DateTime? get dateOfBirth => personal.dateOfBirth;
  String? get nationality => personal.nationality;
  String? get departmentId => job.departmentId;
  String? get managerId => job.managerId;
  String? get jobTitleId => job.jobTitleId;
  DateTime? get hireDate => job.hireDate;
  String get employmentType => job.employmentType;
  String get contractType => job.contractType;
  DateTime? get contractStart => job.contractStart;
  DateTime? get contractEnd => job.contractEnd;
  int? get probationMonths => job.probationMonths;
  String get contractFileUrl => job.contractFileUrl;
  num get basicSalary => compensation.basicSalary;
  num get housingAllowance => compensation.housingAllowance;
  num get transportAllowance => compensation.transportAllowance;
  num get otherAllowance => compensation.otherAllowance;
  String get bankName => compensation.bankName;
  String get iban => compensation.iban;
  String get accountNumber => compensation.accountNumber;
  String get paymentMethod => compensation.paymentMethod;
  String? get maritalStatus => additional.maritalStatus;
  String get address => additional.address;
  String get city => additional.city;
  String get country => additional.country;
  String get passportNo => additional.passportNo;
  DateTime? get passportExpiry => additional.passportExpiry;
  String? get educationLevel => additional.educationLevel;
  String get major => additional.major;
  String get university => additional.university;

  @override
  List<Object?> get props => [personal, job, compensation, additional, loading, success, error];
}
