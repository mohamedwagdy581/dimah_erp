part of 'employee_repo_impl.dart';

mixin _EmployeesRepoExpiryAlertsHelpersMixin on _EmployeesRepoExpirySettingsMixin {
  int _daysLeftFrom(DateTime today, DateTime expiry) {
    final normalizedExpiry = DateTime(expiry.year, expiry.month, expiry.day);
    final normalizedToday = DateTime(today.year, today.month, today.day);
    return normalizedExpiry.difference(normalizedToday).inDays;
  }
}
