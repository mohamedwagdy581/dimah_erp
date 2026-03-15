import 'package:equatable/equatable.dart';

class EmployeeWizardAdditional extends Equatable {
  const EmployeeWizardAdditional({
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

  final String? maritalStatus;
  final String address;
  final String city;
  final String country;
  final String passportNo;
  final DateTime? passportExpiry;
  final String? educationLevel;
  final String major;
  final String university;

  EmployeeWizardAdditional copyWith({
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
    return EmployeeWizardAdditional(
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
