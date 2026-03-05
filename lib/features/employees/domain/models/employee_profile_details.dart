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

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? photoUrl;
  final String status;
  final String? departmentName;
  final String? jobTitleName;
  final DateTime? hireDate;
  final String? nationalId;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? nationality;
  final String? maritalStatus;
  final String? address;
  final String? city;
  final String? country;
  final String? passportNo;
  final DateTime? passportExpiry;
  final DateTime? residencyIssueDate;
  final DateTime? residencyExpiryDate;
  final DateTime? insuranceStartDate;
  final DateTime? insuranceExpiryDate;
  final String? insuranceProvider;
  final String? insurancePolicyNo;
  final String? educationLevel;
  final String? major;
  final String? university;
  final double? basicSalary;
  final double? housingAllowance;
  final double? transportAllowance;
  final double? otherAllowance;
  final List<EmployeeCompensationVersion> compensationHistory;
  final String? bankName;
  final String? iban;
  final String? accountNumber;
  final String? paymentMethod;
  final String? contractType;
  final DateTime? contractStart;
  final DateTime? contractEnd;
  final int? probationMonths;
  final String? contractFileUrl;
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
      hireDate: _parseDate(employee['hire_date']),
      nationalId: employee['national_id']?.toString(),
      dateOfBirth: _parseDate(employee['date_of_birth']),
      gender: employee['gender']?.toString(),
      nationality: personal?['nationality']?.toString() ??
          employee['nationality']?.toString(),
      maritalStatus: personal?['marital_status']?.toString(),
      address: personal?['address']?.toString(),
      city: personal?['city']?.toString(),
      country: personal?['country']?.toString(),
      passportNo: personal?['passport_no']?.toString(),
      passportExpiry: _parseDate(personal?['passport_expiry']),
      residencyIssueDate: _parseDate(personal?['residency_issue_date']),
      residencyExpiryDate: _parseDate(personal?['residency_expiry_date']),
      insuranceStartDate: _parseDate(personal?['insurance_start_date']),
      insuranceExpiryDate: _parseDate(personal?['insurance_expiry_date']),
      insuranceProvider: personal?['insurance_provider']?.toString(),
      insurancePolicyNo: personal?['insurance_policy_no']?.toString(),
      educationLevel:
          personal?['education_level']?.toString() ??
          employee['education']?.toString(),
      major: personal?['major']?.toString(),
      university: personal?['university']?.toString(),
      basicSalary: _parseDouble(compensation?['basic_salary']),
      housingAllowance: _parseDouble(compensation?['housing_allowance']),
      transportAllowance: _parseDouble(compensation?['transport_allowance']),
      otherAllowance: _parseDouble(compensation?['other_allowance']),
      compensationHistory: compensationHistory
          .map(EmployeeCompensationVersion.fromMap)
          .toList(),
      bankName: financial?['bank_name']?.toString(),
      iban: financial?['iban']?.toString(),
      accountNumber: financial?['account_number']?.toString(),
      paymentMethod: financial?['payment_method']?.toString(),
      contractType: contract?['contract_type']?.toString(),
      contractStart: _parseDate(contract?['start_date']),
      contractEnd: _parseDate(contract?['end_date']),
      probationMonths: _parseInt(contract?['probation_months']),
      contractFileUrl: contract?['file_url']?.toString(),
      contractHistory: contractHistory
          .map(EmployeeContractVersion.fromMap)
          .toList(),
      documents: documents.map(EmployeeProfileDocument.fromMap).toList(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

class EmployeeProfileDocument {
  const EmployeeProfileDocument({
    required this.id,
    required this.docType,
    required this.fileUrl,
    this.issuedAt,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String docType;
  final String fileUrl;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  factory EmployeeProfileDocument.fromMap(Map<String, dynamic> map) {
    return EmployeeProfileDocument(
      id: map['id'].toString(),
      docType: (map['doc_type'] ?? 'other').toString(),
      fileUrl: (map['file_url'] ?? '').toString(),
      issuedAt: EmployeeProfileDetails._parseDate(map['issued_at']),
      expiresAt: EmployeeProfileDetails._parseDate(map['expires_at']),
      createdAt: EmployeeProfileDetails._parseDate(map['created_at']),
    );
  }
}

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
      startDate: EmployeeProfileDetails._parseDate(map['start_date']),
      endDate: EmployeeProfileDetails._parseDate(map['end_date']),
      probationMonths: EmployeeProfileDetails._parseInt(map['probation_months']),
      fileUrl: map['file_url']?.toString(),
      createdAt: EmployeeProfileDetails._parseDate(map['created_at']),
    );
  }
}

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
      basicSalary: EmployeeProfileDetails._parseDouble(map['basic_salary']) ?? 0,
      housingAllowance:
          EmployeeProfileDetails._parseDouble(map['housing_allowance']) ?? 0,
      transportAllowance:
          EmployeeProfileDetails._parseDouble(map['transport_allowance']) ?? 0,
      otherAllowance:
          EmployeeProfileDetails._parseDouble(map['other_allowance']) ?? 0,
      effectiveAt: EmployeeProfileDetails._parseDate(map['effective_at']),
      note: map['note']?.toString(),
      createdAt: EmployeeProfileDetails._parseDate(map['created_at']),
    );
  }
}
