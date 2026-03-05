class JournalLine {
  const JournalLine({
    required this.accountId,
    required this.accountName,
    required this.debit,
    required this.credit,
  });

  final String accountId;
  final String accountName;
  final num debit;
  final num credit;
}
