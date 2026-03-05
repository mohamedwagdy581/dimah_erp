import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

class JournalPaginationBar extends StatelessWidget {
  const JournalPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
    required this.pageSize,
    required this.onPageSizeChanged,
  });

  final int page;
  final int totalPages;
  final int total;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final int pageSize;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(t.totalWithValue(total)),
        const SizedBox(width: 12),
        Text(t.pageWithValue(page + 1, totalPages)),
        const Spacer(),
        DropdownButton<int>(
          value: pageSize,
          onChanged: (v) {
            if (v != null) onPageSizeChanged(v);
          },
          items: const [
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 20, child: Text('20')),
            DropdownMenuItem(value: 50, child: Text('50')),
          ],
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: t.previous,
          onPressed: canPrev ? onPrev : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: t.next,
          onPressed: canNext ? onNext : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
