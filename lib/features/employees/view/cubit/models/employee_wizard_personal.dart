import 'package:equatable/equatable.dart';

class EmployeeWizardPersonal extends Equatable {
  const EmployeeWizardPersonal({
    this.employeeNumber = '',
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.photoUrl = '',
    this.nationalId = '',
    this.gender,
    this.dateOfBirth,
    this.nationality,
  });

  final String employeeNumber;
  final String fullName;
  final String email;
  final String phone;
  final String photoUrl;
  final String nationalId;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? nationality;

  EmployeeWizardPersonal copyWith({
    String? employeeNumber,
    String? fullName,
    String? email,
    String? phone,
    String? photoUrl,
    String? nationalId,
    String? gender,
    DateTime? dateOfBirth,
    String? nationality,
  }) {
    return EmployeeWizardPersonal(
      employeeNumber: employeeNumber ?? this.employeeNumber,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      nationalId: nationalId ?? this.nationalId,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
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
  ];
}
