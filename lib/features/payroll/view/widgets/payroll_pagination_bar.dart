import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/page_navigation_buttons.dart';

class PayrollPaginationBar extends StatelessWidget {
  const PayrollPaginationBar({
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
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        Text(
          t.totalWithValue(total),
          style: const TextStyle(
            color: Color(0xFF77738C),
            fontWeight: FontWeight.w600,
          ),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              t.pageWithValue(page + 1, totalPages),
              style: const TextStyle(color: Color(0xFF21194E)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFAFF),
                border: Border.all(color: const Color(0xFFE5DDF2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
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
              ),
            ),
            PageNavigationButtons(
              previousTooltip: t.previous,
              nextTooltip: t.next,
              onPrevious: canPrev ? onPrev : null,
              onNext: canNext ? onNext : null,
            ),
          ],
        ),
      ],
    );
  }
}
