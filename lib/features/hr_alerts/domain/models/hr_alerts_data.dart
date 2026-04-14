import '../../../employees/domain/models/expiry_alert.dart';
import 'government_alert_item.dart';
import 'hr_alert_state_info.dart';

class HrAlertsData {
  const HrAlertsData({
    required this.settings,
    required this.items,
    this.governmentItems = const [],
    this.employeeStates = const {},
    this.governmentStates = const {},
  });

  final ExpiryAlertSettings settings;
  final List<ExpiryAlertItem> items;
  final List<GovernmentAlertItem> governmentItems;
  final Map<String, HrAlertStateInfo> employeeStates;
  final Map<String, HrAlertStateInfo> governmentStates;
}
