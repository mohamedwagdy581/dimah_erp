import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/journal_cubit.dart';
import '../cubit/journal_state.dart';
import '../widgets/journal_pagination_bar.dart';
import '../widgets/journal_table.dart';
import 'journal_table_section_header.dart';
import '../../../view/accounting_ui.dart';
import '../../domain/models/journal_entry.dart';

class JournalTableSection extends StatelessWidget {
  const JournalTableSection({super.key});

  Future<void> _confirmAndPost(
    BuildContext context,
    JournalCubit cubit,
    JournalEntry entry,
  ) async {
    String tr(String ar, String en) => accountingText(context, ar, en);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(tr('ترحيل القيد', 'Post entry')),
        content: Text(
          tr(
            'الترحيل نهائي. سيُحتسب القيد في الدفاتر ولن يمكن تعديله بعد ذلك.',
            'Posting is final. The entry will count in the books and can no longer be edited.',
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('cancel-post'),
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(tr('إلغاء', 'Cancel')),
          ),
          FilledButton(
            key: const ValueKey('confirm-post'),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(tr('ترحيل', 'Post')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final error = await cubit.postEntry(entry.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? tr('تم ترحيل القيد.', 'Entry posted.')
              : accountingErrorText(context, error),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JournalCubit, JournalState>(
      builder: (context, state) {
        final cubit = context.read<JournalCubit>();

        final content = Padding(
          padding: const EdgeInsets.all(16),
          child: accountingPanel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JournalTableSectionHeader(cubit: cubit, state: state),
                const SizedBox(height: 12),
                Expanded(
                  child: AppDataRegion(
                    loading: state.loading,
                    error: state.error,
                    onRetry: cubit.load,
                    child: JournalTable(
                      items: state.items,
                      postingId: state.postingId,
                      onPost: (e) => _confirmAndPost(context, cubit, e),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                JournalPaginationBar(
                  page: state.page,
                  totalPages: state.totalPages,
                  total: state.total,
                  canPrev: state.canPrev,
                  canNext: state.canNext,
                  onPrev: cubit.prevPage,
                  onNext: cubit.nextPage,
                  pageSize: state.pageSize,
                  onPageSizeChanged: cubit.setPageSize,
                ),
              ],
            ),
          ),
        );
        return LayoutBuilder(
          builder: (context, box) {
            if (box.maxHeight < 650 || box.maxWidth < 600) {
              return SingleChildScrollView(
                child: SizedBox(
                  height: box.maxWidth < 600 ? 900 : 700,
                  width: box.maxWidth,
                  child: content,
                ),
              );
            }
            return content;
          },
        );
      },
    );
  }
}
