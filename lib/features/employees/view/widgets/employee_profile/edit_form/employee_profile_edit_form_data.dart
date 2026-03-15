import 'package:flutter/material.dart';

class EmployeeProfileEditFormData {
  const EmployeeProfileEditFormData({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.nationality,
    required this.maritalStatus,
    required this.address,
    required this.city,
    required this.country,
    required this.passportNo,
    required this.insuranceProvider,
    required this.insurancePolicyNo,
    required this.educationLevel,
    required this.major,
    required this.university,
    required this.bankName,
    required this.iban,
    required this.accountNumber,
    required this.contractType,
    required this.probationMonths,
    required this.contractFileUrl,
    required this.status,
    required this.paymentMethod,
    required this.passportExpiry,
    required this.residencyIssueDate,
    required this.residencyExpiryDate,
    required this.insuranceStartDate,
    required this.insuranceExpiryDate,
    required this.contractStart,
    required this.contractEnd,
    required this.saving,
    required this.pickingPhoto,
  });

  final TextEditingController fullName;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController photoUrl;
  final TextEditingController nationality;
  final TextEditingController maritalStatus;
  final TextEditingController address;
  final TextEditingController city;
  final TextEditingController country;
  final TextEditingController passportNo;
  final TextEditingController insuranceProvider;
  final TextEditingController insurancePolicyNo;
  final TextEditingController educationLevel;
  final TextEditingController major;
  final TextEditingController university;
  final TextEditingController bankName;
  final TextEditingController iban;
  final TextEditingController accountNumber;
  final TextEditingController contractType;
  final TextEditingController probationMonths;
  final TextEditingController contractFileUrl;
  final String status;
  final String paymentMethod;
  final DateTime? passportExpiry;
  final DateTime? residencyIssueDate;
  final DateTime? residencyExpiryDate;
  final DateTime? insuranceStartDate;
  final DateTime? insuranceExpiryDate;
  final DateTime? contractStart;
  final DateTime? contractEnd;
  final bool saving;
  final bool pickingPhoto;
}
