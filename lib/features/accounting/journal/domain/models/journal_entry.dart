class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.tenantId,
    required this.entryDate,
    required this.memo,
    required this.totalDebit,
    required this.totalCredit,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String tenantId;
  final DateTime entryDate;
  final String memo;
  final num totalDebit;
  final num totalCredit;
  final String status; // draft / posted
  final DateTime createdAt;

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'].toString(),
      tenantId: map['tenant_id'].toString(),
      entryDate: DateTime.parse(map['entry_date'].toString()),
      memo: (map['memo'] ?? '').toString(),
      totalDebit: (map['total_debit'] ?? 0) as num,
      totalCredit: (map['total_credit'] ?? 0) as num,
      status: (map['status'] ?? 'draft').toString(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
