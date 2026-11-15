abstract class AttendanceIdentityRepo {
  Future<List<Map<String, String>>> fetchAll();
  Future<String?> fetch(String employeeId);
  Future<void> check(String number, {String? employeeId});
  Future<void> save(String employeeId, String number);
}

String normalizeAttendanceNumber(String value) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  return value.trim().split('').map((char) {
    final index = arabic.indexOf(char);
    if (index >= 0) return '$index';
    final other = persian.indexOf(char);
    return other >= 0 ? '$other' : char;
  }).join();
}

bool isValidAttendanceNumber(String value) {
  final normalized = normalizeAttendanceNumber(value);
  return normalized.isEmpty ||
      RegExp(r'^[A-Za-z0-9_-]{1,32}$').hasMatch(normalized);
}
