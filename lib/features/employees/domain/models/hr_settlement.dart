import 'dart:math';
import 'dart:typed_data';
import 'employee.dart';

String newSettlementId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class SettlementAttachment {
  const SettlementAttachment({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
  String get extension => name.split('.').last.toLowerCase();
  bool get isValid =>
      ['pdf', 'jpg', 'jpeg', 'png'].contains(extension) &&
      bytes.isNotEmpty &&
      bytes.length <= 5 * 1024 * 1024;
}

class HrSettlementDraft {
  const HrSettlementDraft({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.finalWorkingDate,
    required this.type,
    required this.gross,
    required this.deductions,
    this.notes = '',
    this.attachment,
  });
  final String id, employeeId, type, notes;
  final DateTime date, finalWorkingDate;
  final double gross, deductions;
  final SettlementAttachment? attachment;
  double get net => gross - deductions;
}

class HrSettlement {
  const HrSettlement({
    required this.id,
    required this.employeeId,
    required this.name,
    this.employeeNumber = '',
    this.type = 'final',
    required this.date,
    required this.finalWorkingDate,
    required this.gross,
    required this.deductions,
    this.notes = '',
    this.filePath,
    this.fileName,
  });
  final String id, employeeId, name, employeeNumber, type, notes;
  final String? filePath, fileName;
  final DateTime? date, finalWorkingDate;
  final double gross, deductions;
  double get net => gross - deductions;
  factory HrSettlement.fromMap(Map<String, dynamic> row) {
    final employee = row['employee'] is Map ? row['employee'] as Map : const {};
    double money(Object? value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    DateTime? date(Object? value) =>
        value == null ? null : DateTime.tryParse('$value');
    return HrSettlement(
      id: '${row['id']}',
      employeeId: '${row['employee_id']}',
      name: '${employee['full_name'] ?? '—'}',
      employeeNumber: '${employee['employee_number'] ?? ''}',
      type: '${row['settlement_type'] ?? 'final'}',
      date: date(row['settlement_date']),
      finalWorkingDate: date(row['final_working_date']),
      gross: money(row['gross_amount']),
      deductions: money(row['deductions_amount']),
      notes: '${row['notes'] ?? ''}',
      filePath: row['attachment_path']?.toString(),
      fileName: row['attachment_name']?.toString(),
    );
  }
}

class HrSettlementsData {
  const HrSettlementsData({
    this.employees = const [],
    this.settlements = const [],
  });
  final List<Employee> employees;
  final List<HrSettlement> settlements;
}
