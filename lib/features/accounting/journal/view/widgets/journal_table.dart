import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/models/journal_entry.dart';
import '../../../view/accounting_ui.dart';
import '../../../../payroll/view/widgets/payroll_format.dart';

class JournalTable extends StatelessWidget {
  const JournalTable({
    super.key,
    required this.items,
    this.onPost,
    this.postingId,
  });

  final List<JournalEntry> items;
  final ValueChanged<JournalEntry>? onPost;
  final String? postingId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: AppEmptyState(
              title: t.noJournalEntriesFound,
              compact: false,
            ),
          ),
        ),
      );
    }

    return AccountingTable(
      minimumWidth: 850,
      headings: [
        t.date,
        t.memo,
        t.debit,
        t.credit,
        t.status,
        accountingText(context, 'إجراء', 'Action'),
      ],
      widths: const [16, 36, 14, 14, 12, 8],
      rows: [
        for (final e in items)
          [
            Text(
              _formatDate(e.entryDate),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
            ),
            SelectableText(e.memo.isEmpty ? '—' : e.memo),
            Text(
              payrollMoney(e.totalDebit),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
            ),
            Text(
              payrollMoney(e.totalCredit),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
            ),
            Center(
              child: accountingBadge(
                e.status == 'draft'
                    ? t.draft
                    : e.status == 'posted'
                    ? t.posted
                    : e.status,
                active: e.status == 'posted',
              ),
            ),
            Center(
              child: e.status != 'draft' || onPost == null
                  ? const SizedBox.shrink()
                  : postingId == e.id
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      key: ValueKey('post-entry-${e.id}'),
                      tooltip: accountingText(context, 'ترحيل', 'Post'),
                      onPressed: postingId == null ? () => onPost!(e) : null,
                      icon: const Icon(Icons.task_alt, color: accountingPurple),
                    ),
            ),
          ],
      ],
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}
