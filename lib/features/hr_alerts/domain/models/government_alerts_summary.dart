import 'government_alert_item.dart';

class GovernmentAlertsSummary {
  const GovernmentAlertsSummary({
    required this.total,
    required this.expired,
    required this.urgent,
    required this.upcoming,
  });

  final int total;
  final int expired;
  final int urgent;
  final int upcoming;

  factory GovernmentAlertsSummary.fromItems(List<GovernmentAlertItem> items) {
    var expired = 0;
    var urgent = 0;
    var upcoming = 0;
    for (final item in items) {
      if (item.daysLeft < 0) {
        expired++;
      } else if (item.daysLeft < 30) {
        urgent++;
      } else if (item.daysLeft < 90) {
        upcoming++;
      }
    }
    return GovernmentAlertsSummary(
      total: items.length,
      expired: expired,
      urgent: urgent,
      upcoming: upcoming,
    );
  }
}
