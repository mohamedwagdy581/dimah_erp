import 'package:equatable/equatable.dart';

class EmployeeWizardState extends Equatable {
  const EmployeeWizardState({
    this.employeeNumber = '',
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.photoUrl = '',
    this.nationalId = '',
    this.gender,
    this.dateOfBirth,
    this.nationality,
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
    this.basicSalary = 0,
    this.housingAllowance = 0,
    this.transportAllowance = 0,
    this.otherAllowance = 0,
    this.bankName = '',
    this.iban = '',
    this.accountNumber = '',
    this.paymentMethod = 'bank',
    this.loading = false,
    this.success = false,
    this.error,
    this.maritalStatus,
    this.address = '',
    this.city = '',
    this.country = '',
    this.passportNo = '',
    this.passportExpiry,
    this.educationLevel,
    this.major = '',
    this.university = '',
  });

  // ===== Personal =====
  final String employeeNumber;
  final String fullName;
  final String email;
  final String phone;
  final String photoUrl;
  final String nationalId;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? nationality;

  // ===== Job =====
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

  // ===== Compensation =====
  final num basicSalary;
  final num housingAllowance;
  final num transportAllowance;
  final num otherAllowance;
  final String bankName;
  final String iban;
  final String accountNumber;
  final String paymentMethod;

  // ===== Status =====
  final bool loading;
  final bool success;
  final String? error;
  final String? maritalStatus;
  final String address;
  final String city;
  final String country;
  final String passportNo;
  final DateTime? passportExpiry;
  final String? educationLevel;
  final String major;
  final String university;

  EmployeeWizardState copyWith({
    String? employeeNumber,
    String? fullName,
    String? email,
    String? phone,
    String? photoUrl,
    String? nationalId,
    String? gender,
    DateTime? dateOfBirth,
    String? nationality,
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
    num? basicSalary,
    num? housingAllowance,
    num? transportAllowance,
    num? otherAllowance,
    String? bankName,
    String? iban,
    String? accountNumber,
    String? paymentMethod,
    bool? loading,
    bool? success,
    String? error,
    String? maritalStatus,
    String? address,
    String? city,
    String? country,
    String? passportNo,
    DateTime? passportExpiry,
    String? educationLevel,
    String? major,
    String? university,
  }) {
    return EmployeeWizardState(
      employeeNumber: employeeNumber ?? this.employeeNumber,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      nationalId: nationalId ?? this.nationalId,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
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
      basicSalary: basicSalary ?? this.basicSalary,
      housingAllowance: housingAllowance ?? this.housingAllowance,
      transportAllowance: transportAllowance ?? this.transportAllowance,
      otherAllowance: otherAllowance ?? this.otherAllowance,
      bankName: bankName ?? this.bankName,
      iban: iban ?? this.iban,
      accountNumber: accountNumber ?? this.accountNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      loading: loading ?? this.loading,
      success: success ?? this.success,
      error: error,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      passportNo: passportNo ?? this.passportNo,
      passportExpiry: passportExpiry ?? this.passportExpiry,
      educationLevel: educationLevel ?? this.educationLevel,
      major: major ?? this.major,
      university: university ?? this.university,
    );
  }

  @override
  List<Object?> get props => [
    employeeNumber,
    fullName,
    email,
    phone,
    photoUrl,
    nationalId,
    gender,
    dateOfBirth,
    nationality,
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
    basicSalary,
    housingAllowance,
    transportAllowance,
    otherAllowance,
    bankName,
    iban,
    accountNumber,
    paymentMethod,
    loading,
    success,
    error,
    maritalStatus,
    address,
    city,
    country,
    passportNo,
    passportExpiry,
    educationLevel,
    major,
    university,
  ];
}
