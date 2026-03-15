import 'package:flutter/material.dart';

import '../../../../../../core/di/app_di.dart';

Future<void> submitEmployeeProfileEdits({
  required String employeeId,
  required Map<String, TextEditingController> controllers,
  required String status,
  required String paymentMethod,
  required DateTime? passportExpiry,
  required DateTime? residencyIssueDate,
  required DateTime? residencyExpiryDate,
  required DateTime? insuranceStartDate,
  required DateTime? insuranceExpiryDate,
  required DateTime? contractStart,
  required DateTime? contractEnd,
}) {
  return AppDI.employeesRepo.updateEmployeeProfile(
    employeeId: employeeId,
    fullName: controllers['fullName']!.text.trim(),
    email: controllers['email']!.text.trim(),
    phone: controllers['phone']!.text.trim(),
    photoUrl: controllers['photoUrl']!.text.trim(),
    status: status,
    nationality: controllers['nationality']!.text.trim(),
    maritalStatus: controllers['maritalStatus']!.text.trim(),
    address: controllers['address']!.text.trim(),
    city: controllers['city']!.text.trim(),
    country: controllers['country']!.text.trim(),
    passportNo: controllers['passportNo']!.text.trim(),
    passportExpiry: passportExpiry,
    residencyIssueDate: residencyIssueDate,
    residencyExpiryDate: residencyExpiryDate,
    insuranceStartDate: insuranceStartDate,
    insuranceExpiryDate: insuranceExpiryDate,
    insuranceProvider: controllers['insuranceProvider']!.text.trim(),
    insurancePolicyNo: controllers['insurancePolicyNo']!.text.trim(),
    educationLevel: controllers['educationLevel']!.text.trim(),
    major: controllers['major']!.text.trim(),
    university: controllers['university']!.text.trim(),
    bankName: controllers['bankName']!.text.trim(),
    iban: controllers['iban']!.text.trim(),
    accountNumber: controllers['accountNumber']!.text.trim(),
    paymentMethod: paymentMethod,
    contractType: controllers['contractType']!.text.trim(),
    contractStart: contractStart,
    contractEnd: contractEnd,
    probationMonths: int.tryParse(
      controllers['probationMonths']!.text.trim(),
    ),
    contractFileUrl: controllers['contractFileUrl']!.text.trim(),
  );
}
