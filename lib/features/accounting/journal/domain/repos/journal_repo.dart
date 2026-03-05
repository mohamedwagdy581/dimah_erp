import '../models/journal_entry.dart';
import '../models/journal_line.dart';

abstract class JournalRepo {
  Future<({List<JournalEntry> items, int total})> fetchEntries({
    required int page,
    required int pageSize,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String sortBy,
    bool ascending,
  });

  Future<void> createEntry({
    required DateTime entryDate,
    required String memo,
    required List<JournalLine> lines,
  });
}
