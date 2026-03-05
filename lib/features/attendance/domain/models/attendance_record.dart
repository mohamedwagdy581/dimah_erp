class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.tenantId,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String tenantId;
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final String status;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? notes;
  final DateTime createdAt;

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    final employee = map['employee'];
    return AttendanceRecord(
      id: map['id'].toString(),
      tenantId: map['tenant_id'].toString(),
      employeeId: map['employee_id'].toString(),
      employeeName:
          employee is Map ? (employee['full_name'] ?? '').toString() : '',
      date: DateTime.parse(map['date'].toString()),
      status: (map['status'] ?? 'present').toString(),
      checkIn: map['check_in'] == null
          ? null
          : DateTime.tryParse(map['check_in'].toString()),
      checkOut: map['check_out'] == null
          ? null
          : DateTime.tryParse(map['check_out'].toString()),
      notes: map['notes']?.toString(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
