import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class AlertsBand {
  const AlertsBand({required this.label, required this.fg, required this.bg});

  final String label;
  final Color fg;
  final Color bg;
}

AlertsBand alertBand(BuildContext context, int daysLeft) {
  final t = AppLocalizations.of(context)!;
  if (daysLeft < 0) {
    return AlertsBand(label: t.hrBandExpired, fg: Colors.red.shade800, bg: Colors.red.withValues(alpha: 0.18));
  }
  if (daysLeft < 30) {
    return AlertsBand(label: t.hrBandUrgent, fg: Colors.red.shade700, bg: Colors.red.withValues(alpha: 0.12));
  }
  if (daysLeft < 90) {
    return AlertsBand(label: t.hrBandWarning, fg: Colors.amber.shade800, bg: Colors.amber.withValues(alpha: 0.20));
  }
  if (daysLeft <= 120) {
    return AlertsBand(label: t.hrBandUpcoming, fg: Colors.yellow.shade900, bg: Colors.yellow.withValues(alpha: 0.18));
  }
  return AlertsBand(label: t.hrBandSafe, fg: Colors.green.shade800, bg: Colors.green.withValues(alpha: 0.14));
}

String formatAlertDate(DateTime d) {
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

String alertTypeLabel(BuildContext context, String type) {
  final t = AppLocalizations.of(context)!;
  if (type == 'contract') return t.hrTypeContract;
  if (type == 'residency') return t.hrTypeResidency;
  if (type == 'insurance') return t.hrTypeInsurance;
  if (type.startsWith('document:')) {
    final docType = type.substring('document:'.length);
    return '${t.hrTypeDocument}: ${documentTypeLabel(t, docType)}';
  }
  return type;
}

String documentTypeLabel(AppLocalizations t, String docType) {
  switch (docType) {
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
