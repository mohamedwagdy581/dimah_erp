class GovernmentAlertItem {
  const GovernmentAlertItem({
    required this.id,
    required this.title,
    required this.alertType,
    required this.startDate,
    required this.endDate,
    required this.daysLeft,
    this.description,
    this.fileName,
    this.fileUrl,
  });

  final String id;
  final String title;
  final String alertType;
  final DateTime startDate;
  final DateTime endDate;
  final int daysLeft;
  final String? description;
  final String? fileName;
  final String? fileUrl;
}
