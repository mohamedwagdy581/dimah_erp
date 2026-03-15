import '../../../../core/di/app_di.dart';
import '../../../employees/domain/models/expiry_alert.dart';
import '../../domain/models/hr_alerts_data.dart';

class HrAlertsRepo {
  Future<HrAlertsData> load() async {
    final settings = await AppDI.employeesRepo.fetchExpiryAlertSettings();
    final items = await AppDI.employeesRepo.fetchExpiryAlerts();
    return HrAlertsData(settings: settings, items: items);
  }

  Future<void> saveSettings(ExpiryAlertSettings settings) {
    return AppDI.employeesRepo.upsertExpiryAlertSettings(settings);
  }
}
