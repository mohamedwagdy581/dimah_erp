class EmployeeDraft {
  final String? employeeNumber;
  final String fullName;
  final String? email;
  final String? phone;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? nationalId;
  final String? nationality;
  final String? education;

  const EmployeeDraft({
    this.employeeNumber,
    required this.fullName,
    this.email,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.nationalId,
    this.nationality,
    this.education,
  });

  EmployeeDraft copyWith({
    String? employeeNumber,
    String? fullName,
    String? email,
    String? phone,
    String? gender,
    DateTime? dateOfBirth,
    String? nationalId,
    String? nationality,
    String? education,
  }) {
    return EmployeeDraft(
      employeeNumber: employeeNumber ?? this.employeeNumber,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationalId: nationalId ?? this.nationalId,
      nationality: nationality ?? this.nationality,
      education: education ?? this.education,
    );
  }
}
