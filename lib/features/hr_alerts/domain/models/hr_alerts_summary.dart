import '../../../employees/domain/models/expiry_alert.dart';

class HrAlertsSummary {
  const HrAlertsSummary({
    required this.total,
    required this.expired,
    required this.urgent,
    required this.documents,
    required this.contracts,
  });

  final int total;
  final int expired;
  final int urgent;
  final int documents;
  final int contracts;

  factory HrAlertsSummary.fromItems(List<ExpiryAlertItem> items) {
    var expired = 0;
    var urgent = 0;
    var documents = 0;
    var contracts = 0;
    for (final item in items) {
      if (item.daysLeft < 0) expired++;
      if (item.daysLeft >= 0 && item.daysLeft < 30) urgent++;
      if (item.type.startsWith('document:')) documents++;
      if (item.type == 'contract') contracts++;
    }
    return HrAlertsSummary(
      total: items.length,
      expired: expired,
      urgent: urgent,
      documents: documents,
      contracts: contracts,
    );
  }
}
