import '../../../employees/domain/models/expiry_alert.dart';

class HrAlertsData {
  const HrAlertsData({required this.settings, required this.items});

  final ExpiryAlertSettings settings;
  final List<ExpiryAlertItem> items;
}
