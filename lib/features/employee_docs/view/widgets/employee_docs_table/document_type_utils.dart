import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

String docTypeLabel(AppLocalizations t, String type) {
  switch (type) {
    case 'id_card':
      return t.idCard;
    case 'passport':
      return t.passport;
    case 'cv':
      return 'CV';
    case 'graduation_cert':
      return t.graduationCert;
    case 'national_address':
      return t.nationalAddress;
    case 'bank_iban_certificate':
      return t.bankIbanCertificate;
    case 'salary_certificate':
      return t.salaryCertificate;
    case 'salary_definition':
      return t.salaryDefinition;
    case 'contract':
      return t.contract;
    case 'residency':
      return t.residencyDocument;
    case 'driving_license':
      return t.drivingLicense;
    case 'offer_letter':
      return t.offerLetter;
    case 'medical_insurance':
      return t.medicalInsurance;
    case 'medical_report':
      return t.medicalReport;
    default:
      return t.other;
  }
}

IconData iconForDocType(String type) {
  switch (type) {
    case 'id_card':
    case 'passport':
    case 'residency':
    case 'national_address':
      return Icons.badge_outlined;
    case 'cv':
    case 'offer_letter':
    case 'salary_certificate':
    case 'salary_definition':
    case 'graduation_cert':
      return Icons.description_outlined;
    case 'bank_iban_certificate':
      return Icons.account_balance_outlined;
    case 'contract':
      return Icons.assignment_outlined;
    case 'driving_license':
      return Icons.directions_car_outlined;
    case 'medical_insurance':
    case 'medical_report':
      return Icons.health_and_safety_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

Color iconColorForDocType(BuildContext context, String type) {
  final theme = Theme.of(context);
  switch (type) {
    case 'id_card':
    case 'passport':
    case 'residency':
    case 'national_address':
      return theme.colorScheme.primary;
    case 'bank_iban_certificate':
    case 'salary_certificate':
    case 'salary_definition':
      return Colors.teal;
    case 'medical_insurance':
    case 'medical_report':
      return Colors.redAccent;
    case 'contract':
    case 'offer_letter':
      return Colors.deepPurpleAccent;
    case 'graduation_cert':
    case 'cv':
      return Colors.indigo;
    default:
      return theme.colorScheme.secondary;
  }
}

String fileTypeLabel(AppLocalizations t, String fileUrl) {
  final lastSegment = Uri.tryParse(fileUrl)?.pathSegments.last;
  final rawExt = lastSegment?.split('.').last;
  final ext = rawExt?.toUpperCase();
  if (ext == null || ext.isEmpty || ext == (lastSegment?.toUpperCase())) {
    return t.documentFile;
  }
  return '$ext ${t.file}';
}
