class AttendanceImportRecord {
  const AttendanceImportRecord({
    required this.employeeId,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.notes,
  });

  final String employeeId;
  final DateTime date;
  final String status;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? notes;
}
