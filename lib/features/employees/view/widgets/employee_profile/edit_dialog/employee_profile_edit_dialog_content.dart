import 'package:flutter/material.dart';

import '../edit_form/employee_profile_edit_form_callbacks.dart';
import '../edit_form/employee_profile_edit_form_data.dart';
import '../employee_profile_edit_form.dart';

class EmployeeProfileEditDialogContent extends StatelessWidget {
  const EmployeeProfileEditDialogContent({
    super.key,
    required this.formKey,
    required this.controllers,
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
    required this.onPickPhoto,
    required this.onStatusChanged,
    required this.onPaymentMethodChanged,
    required this.onPickPassportExpiry,
    required this.onPickResidencyIssueDate,
    required this.onPickResidencyExpiryDate,
    required this.onPickInsuranceStartDate,
    required this.onPickInsuranceExpiryDate,
    required this.onPickContractStart,
    required this.onPickContractEnd,
  });

  final GlobalKey<FormState> formKey;
  final Map<String, TextEditingController> controllers;
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
  final VoidCallback onPickPhoto;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onPaymentMethodChanged;
  final VoidCallback onPickPassportExpiry;
  final VoidCallback onPickResidencyIssueDate;
  final VoidCallback onPickResidencyExpiryDate;
  final VoidCallback onPickInsuranceStartDate;
  final VoidCallback onPickInsuranceExpiryDate;
  final VoidCallback onPickContractStart;
  final VoidCallback onPickContractEnd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 720,
      child: Form(
        key: formKey,
        child: EmployeeProfileEditForm(
          data: EmployeeProfileEditFormData(
            fullName: controllers['fullName']!,
            email: controllers['email']!,
            phone: controllers['phone']!,
            photoUrl: controllers['photoUrl']!,
            nationality: controllers['nationality']!,
            maritalStatus: controllers['maritalStatus']!,
            address: controllers['address']!,
            city: controllers['city']!,
            country: controllers['country']!,
            passportNo: controllers['passportNo']!,
            insuranceProvider: controllers['insuranceProvider']!,
            insurancePolicyNo: controllers['insurancePolicyNo']!,
            educationLevel: controllers['educationLevel']!,
            major: controllers['major']!,
            university: controllers['university']!,
            bankName: controllers['bankName']!,
            iban: controllers['iban']!,
            accountNumber: controllers['accountNumber']!,
            contractType: controllers['contractType']!,
            probationMonths: controllers['probationMonths']!,
            contractFileUrl: controllers['contractFileUrl']!,
            status: status,
            paymentMethod: paymentMethod,
            passportExpiry: passportExpiry,
            residencyIssueDate: residencyIssueDate,
            residencyExpiryDate: residencyExpiryDate,
            insuranceStartDate: insuranceStartDate,
            insuranceExpiryDate: insuranceExpiryDate,
            contractStart: contractStart,
            contractEnd: contractEnd,
            saving: saving,
            pickingPhoto: pickingPhoto,
          ),
          callbacks: EmployeeProfileEditFormCallbacks(
            onPickPhoto: onPickPhoto,
            onStatusChanged: onStatusChanged,
            onPaymentMethodChanged: onPaymentMethodChanged,
            onPickPassportExpiry: onPickPassportExpiry,
            onPickResidencyIssueDate: onPickResidencyIssueDate,
            onPickResidencyExpiryDate: onPickResidencyExpiryDate,
            onPickInsuranceStartDate: onPickInsuranceStartDate,
            onPickInsuranceExpiryDate: onPickInsuranceExpiryDate,
            onPickContractStart: onPickContractStart,
            onPickContractEnd: onPickContractEnd,
          ),
        ),
      ),
    );
  }
}
