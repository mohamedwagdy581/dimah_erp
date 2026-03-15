part 'employee_profile_details_parsers.dart';
part 'employee_profile_document.dart';
part 'employee_contract_version.dart';
part 'employee_compensation_version.dart';

class EmployeeProfileDetails {
  const EmployeeProfileDetails({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.status,
    this.departmentName,
    this.jobTitleName,
    this.hireDate,
    this.nationalId,
    this.dateOfBirth,
    this.gender,
    this.nationality,
    this.maritalStatus,
    this.address,
    this.city,
    this.country,
    this.passportNo,
    this.passportExpiry,
    this.residencyIssueDate,
    this.residencyExpiryDate,
    this.insuranceStartDate,
    this.insuranceExpiryDate,
    this.insuranceProvider,
    this.insurancePolicyNo,
    this.educationLevel,
    this.major,
    this.university,
    this.basicSalary,
    this.housingAllowance,
    this.transportAllowance,
    this.otherAllowance,
    this.compensationHistory = const [],
    this.bankName,
    this.iban,
    this.accountNumber,
    this.paymentMethod,
    this.contractType,
    this.contractStart,
    this.contractEnd,
    this.probationMonths,
    this.contractFileUrl,
    this.contractHistory = const [],
    this.documents = const [],
  });

  final String id, fullName, email, phone, status;
  final String? photoUrl, departmentName, jobTitleName, nationalId;
  final String? gender, nationality, maritalStatus, address, city, country;
  final String? passportNo, insuranceProvider, insurancePolicyNo;
  final String? educationLevel, major, university;
  final String? bankName, iban, accountNumber, paymentMethod, contractType;
  final String? contractFileUrl;
  final DateTime? hireDate, dateOfBirth, passportExpiry;
  final DateTime? residencyIssueDate, residencyExpiryDate;
  final DateTime? insuranceStartDate, insuranceExpiryDate;
  final DateTime? contractStart, contractEnd;
  final double? basicSalary, housingAllowance, transportAllowance, otherAllowance;
  final List<EmployeeCompensationVersion> compensationHistory;
  final int? probationMonths;
  final List<EmployeeContractVersion> contractHistory;
  final List<EmployeeProfileDocument> documents;

  factory EmployeeProfileDetails.fromMaps({
    required Map<String, dynamic> employee,
    Map<String, dynamic>? personal,
    Map<String, dynamic>? compensation,
    List<Map<String, dynamic>> compensationHistory = const [],
    Map<String, dynamic>? financial,
    Map<String, dynamic>? contract,
    List<Map<String, dynamic>> contractHistory = const [],
    List<Map<String, dynamic>> documents = const [],
  }) {
    final department = employee['department'];
    final jobTitle = employee['job_title'];

    return EmployeeProfileDetails(
      id: employee['id'].toString(),
      fullName: (employee['full_name'] ?? '').toString(),
      email: (employee['email'] ?? '').toString(),
      phone: (employee['phone'] ?? '').toString(),
      photoUrl: employee['photo_url']?.toString(),
      status: (employee['status'] ?? 'active').toString(),
      departmentName:
          department is Map ? department['name']?.toString() : null,
      jobTitleName: jobTitle is Map ? jobTitle['name']?.toString() : null,
      hireDate: parseEmployeeProfileDate(employee['hire_date']),
      nationalId: employee['national_id']?.toString(),
      dateOfBirth: parseEmployeeProfileDate(employee['date_of_birth']),
      gender: employee['gender']?.toString(),
      nationality:
          personal?['nationality']?.toString() ??
          employee['nationality']?.toString(),
      maritalStatus: personal?['marital_status']?.toString(),
      address: personal?['address']?.toString(),
      city: personal?['city']?.toString(),
      country: personal?['country']?.toString(),
      passportNo: personal?['passport_no']?.toString(),
      passportExpiry: parseEmployeeProfileDate(personal?['passport_expiry']),
      residencyIssueDate:
          parseEmployeeProfileDate(personal?['residency_issue_date']),
      residencyExpiryDate:
          parseEmployeeProfileDate(personal?['residency_expiry_date']),
      insuranceStartDate:
          parseEmployeeProfileDate(personal?['insurance_start_date']),
      insuranceExpiryDate:
          parseEmployeeProfileDate(personal?['insurance_expiry_date']),
      insuranceProvider: personal?['insurance_provider']?.toString(),
      insurancePolicyNo: personal?['insurance_policy_no']?.toString(),
      educationLevel:
          personal?['education_level']?.toString() ??
          employee['education']?.toString(),
      major: personal?['major']?.toString(),
      university: personal?['university']?.toString(),
      basicSalary: parseEmployeeProfileDouble(compensation?['basic_salary']),
      housingAllowance:
          parseEmployeeProfileDouble(compensation?['housing_allowance']),
      transportAllowance:
          parseEmployeeProfileDouble(compensation?['transport_allowance']),
      otherAllowance: parseEmployeeProfileDouble(compensation?['other_allowance']),
      compensationHistory:
          compensationHistory.map(EmployeeCompensationVersion.fromMap).toList(),
      bankName: financial?['bank_name']?.toString(),
      iban: financial?['iban']?.toString(),
      accountNumber: financial?['account_number']?.toString(),
      paymentMethod: financial?['payment_method']?.toString(),
      contractType: contract?['contract_type']?.toString(),
      contractStart: parseEmployeeProfileDate(contract?['start_date']),
      contractEnd: parseEmployeeProfileDate(contract?['end_date']),
      probationMonths: parseEmployeeProfileInt(contract?['probation_months']),
      contractFileUrl: contract?['file_url']?.toString(),
      contractHistory:
          contractHistory.map(EmployeeContractVersion.fromMap).toList(),
      documents: documents.map(EmployeeProfileDocument.fromMap).toList(),
    );
  }
}
