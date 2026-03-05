import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/models/journal_entry.dart';

class JournalTable extends StatelessWidget {
  const JournalTable({super.key, required this.items});

  final List<JournalEntry> items;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text(t.noJournalEntriesFound)),
        ),
      );
    }

    return Card(
      child: LayoutBuilder(
        builder: (context, c) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: c.maxWidth),
              child: DataTable(
                columns: [
                  DataColumn(label: Text(t.date)),
                  DataColumn(label: Text(t.memo)),
                  DataColumn(label: Text(t.debit)),
                  DataColumn(label: Text(t.credit)),
                  DataColumn(label: Text(t.status)),
                ],
                rows: items.map((e) {
                  return DataRow(
                    cells: [
                      DataCell(Text(_formatDate(e.entryDate))),
                      DataCell(Text(e.memo)),
                      DataCell(Text(e.totalDebit.toStringAsFixed(2))),
                      DataCell(Text(e.totalCredit.toStringAsFixed(2))),
                      DataCell(Text(e.status)),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}
