part of 'dashboard_page.dart';

class _PendingItem {
  const _PendingItem({
    required this.employeeName,
    required this.requestType,
    required this.createdAt,
  });

  final String employeeName;
  final String requestType;
  final DateTime createdAt;
}

class _HrDashboardData {
  const _HrDashboardData({
    this.activeEmployees = 0,
    this.pendingApprovals = 0,
    this.onLeaveToday = 0,
    this.missingCheckInToday = 0,
    this.leavesThisMonth = 0,
    this.checkedInToday = 0,
    this.lateToday = 0,
    this.overtimeToday = 0,
    this.todayAttentionItems = const [],
    this.pendingItems = const [],
    this.expiringDocuments = const [],
    this.totalExpiryAlerts = 0,
    this.urgentExpiryAlerts = 0,
    this.expiredDocumentsCount = 0,
    this.totalDocumentsWithExpiry = 0,
    this.validDocumentsWithExpiry = 0,
    this.expiringDocumentTypeCounts = const {},
  });

  final int activeEmployees;
  final int pendingApprovals;
  final int onLeaveToday;
  final int missingCheckInToday;
  final int leavesThisMonth;
  final int checkedInToday;
  final int lateToday;
  final int overtimeToday;
  final List<_AttendanceAttentionItem> todayAttentionItems;
  final List<_PendingItem> pendingItems;
  final List<Map<String, dynamic>> expiringDocuments;
  final int totalExpiryAlerts;
  final int urgentExpiryAlerts;
  final int expiredDocumentsCount;
  final int totalDocumentsWithExpiry;
  final int validDocumentsWithExpiry;
  final Map<String, int> expiringDocumentTypeCounts;

  double get checkInCoverage {
    if (activeEmployees <= 0) return 0;
    return checkedInToday / activeEmployees;
  }

  double get approvalLoad {
    if (activeEmployees <= 0) return 0;
    return pendingApprovals / activeEmployees;
  }

  double get documentCompliance {
    if (totalDocumentsWithExpiry <= 0) return 0;
    return validDocumentsWithExpiry / totalDocumentsWithExpiry;
  }
}

class _AttendanceAttentionItem {
  const _AttendanceAttentionItem({
    required this.employeeName,
    required this.type,
    required this.valueLabel,
    required this.value,
  });

  final String employeeName;
  final String type;
  final String valueLabel;
  final int value;
}

String _labelForDocumentType(AppLocalizations t, String type) {
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
      return t.documentLabel;
  }
}
