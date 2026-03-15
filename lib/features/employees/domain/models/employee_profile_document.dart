part of 'employee_profile_details.dart';

class EmployeeProfileDocument {
  const EmployeeProfileDocument({
    required this.id,
    required this.docType,
    required this.fileUrl,
    this.issuedAt,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String docType;
  final String fileUrl;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  factory EmployeeProfileDocument.fromMap(Map<String, dynamic> map) {
    return EmployeeProfileDocument(
      id: map['id'].toString(),
      docType: (map['doc_type'] ?? 'other').toString(),
      fileUrl: (map['file_url'] ?? '').toString(),
      issuedAt: parseEmployeeProfileDate(map['issued_at']),
      expiresAt: parseEmployeeProfileDate(map['expires_at']),
      createdAt: parseEmployeeProfileDate(map['created_at']),
    );
  }
}
