class ExpiryAlertSettings {
  const ExpiryAlertSettings({
    required this.contractAlertDays,
    required this.residencyAlertDays,
    required this.insuranceAlertDays,
  });

  final int contractAlertDays;
  final int residencyAlertDays;
  final int insuranceAlertDays;
}

class ExpiryAlertItem {
  const ExpiryAlertItem({
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.expiryDate,
    required this.daysLeft,
  });

  final String employeeId;
  final String employeeName;
  final String type;
  final DateTime expiryDate;
  final int daysLeft;
}
