import 'package:flutter/material.dart';

import '../../../../domain/models/employee_profile_details.dart';

Map<String, TextEditingController> buildEmployeeProfileEditControllers(
  EmployeeProfileDetails profile,
) {
  return {
    'fullName': TextEditingController(text: profile.fullName),
    'email': TextEditingController(text: profile.email),
    'phone': TextEditingController(text: profile.phone),
    'photoUrl': TextEditingController(text: profile.photoUrl ?? ''),
    'nationality': TextEditingController(text: profile.nationality ?? ''),
    'maritalStatus': TextEditingController(text: profile.maritalStatus ?? ''),
    'address': TextEditingController(text: profile.address ?? ''),
    'city': TextEditingController(text: profile.city ?? ''),
    'country': TextEditingController(text: profile.country ?? ''),
    'passportNo': TextEditingController(text: profile.passportNo ?? ''),
    'insuranceProvider': TextEditingController(
      text: profile.insuranceProvider ?? '',
    ),
    'insurancePolicyNo': TextEditingController(
      text: profile.insurancePolicyNo ?? '',
    ),
    'educationLevel': TextEditingController(
      text: profile.educationLevel ?? '',
    ),
    'major': TextEditingController(text: profile.major ?? ''),
    'university': TextEditingController(text: profile.university ?? ''),
    'bankName': TextEditingController(text: profile.bankName ?? ''),
    'iban': TextEditingController(text: profile.iban ?? ''),
    'accountNumber': TextEditingController(text: profile.accountNumber ?? ''),
    'contractType': TextEditingController(
      text: profile.contractType ?? 'full_time',
    ),
    'probationMonths': TextEditingController(
      text: profile.probationMonths == null ? '' : '${profile.probationMonths}',
    ),
    'contractFileUrl': TextEditingController(
      text: profile.contractFileUrl ?? '',
    ),
  };
}

void disposeEmployeeProfileEditControllers(
  Map<String, TextEditingController> controllers,
) {
  for (final controller in controllers.values) {
    controller.dispose();
  }
}
