import 'package:flutter/material.dart';

import 'edit_form/employee_profile_edit_form_callbacks.dart';
import 'edit_form/employee_profile_edit_form_data.dart';
import 'edit_form/employee_profile_edit_education_insurance_section.dart';
import 'edit_form/employee_profile_edit_financial_contract_section.dart';
import 'edit_form/employee_profile_edit_personal_section.dart';
import 'edit_form/employee_profile_edit_top_sections.dart';

class EmployeeProfileEditForm extends StatelessWidget {
  const EmployeeProfileEditForm({
    super.key,
    required this.data,
    required this.callbacks,
  });

  final EmployeeProfileEditFormData data;
  final EmployeeProfileEditFormCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmployeeProfileBasicFields(
            fullName: data.fullName,
            email: data.email,
            phone: data.phone,
          ),
          const SizedBox(height: 10),
          EmployeeProfilePhotoSection(
            photoUrl: data.photoUrl,
            saving: data.saving,
            pickingPhoto: data.pickingPhoto,
            onPickPhoto: callbacks.onPickPhoto,
          ),
          const SizedBox(height: 10),
          EmployeeProfileStatusSection(
            status: data.status,
            paymentMethod: data.paymentMethod,
            onStatusChanged: callbacks.onStatusChanged,
            onPaymentMethodChanged: callbacks.onPaymentMethodChanged,
          ),
          const SizedBox(height: 10),
          EmployeeProfilePersonalSection(
            nationality: data.nationality,
            maritalStatus: data.maritalStatus,
            address: data.address,
            city: data.city,
            country: data.country,
            passportNo: data.passportNo,
            passportExpiry: data.passportExpiry,
            residencyIssueDate: data.residencyIssueDate,
            residencyExpiryDate: data.residencyExpiryDate,
            onPickPassportExpiry: callbacks.onPickPassportExpiry,
            onPickResidencyIssueDate: callbacks.onPickResidencyIssueDate,
            onPickResidencyExpiryDate: callbacks.onPickResidencyExpiryDate,
          ),
          const SizedBox(height: 10),
          EmployeeProfileEducationInsuranceSection(
            insuranceProvider: data.insuranceProvider,
            insurancePolicyNo: data.insurancePolicyNo,
            educationLevel: data.educationLevel,
            major: data.major,
            university: data.university,
            insuranceStartDate: data.insuranceStartDate,
            insuranceExpiryDate: data.insuranceExpiryDate,
            onPickInsuranceStartDate: callbacks.onPickInsuranceStartDate,
            onPickInsuranceExpiryDate: callbacks.onPickInsuranceExpiryDate,
          ),
          const SizedBox(height: 10),
          EmployeeProfileFinancialContractSection(
            bankName: data.bankName,
            iban: data.iban,
            accountNumber: data.accountNumber,
            contractType: data.contractType,
            probationMonths: data.probationMonths,
            contractFileUrl: data.contractFileUrl,
            contractStart: data.contractStart,
            contractEnd: data.contractEnd,
            onPickContractStart: callbacks.onPickContractStart,
            onPickContractEnd: callbacks.onPickContractEnd,
          ),
        ],
      ),
    );
  }
}
