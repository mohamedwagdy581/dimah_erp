import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/journal_cubit.dart';
import '../cubit/journal_state.dart';
import '../widgets/journal_pagination_bar.dart';
import '../widgets/journal_table.dart';
import 'journal_table_section_header.dart';

class JournalTableSection extends StatelessWidget {
  const JournalTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JournalCubit, JournalState>(
      builder: (context, state) {
        final cubit = context.read<JournalCubit>();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JournalTableSectionHeader(cubit: cubit, state: state),
              const SizedBox(height: 12),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              Expanded(child: JournalTable(items: state.items)),
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
        );
      },
    );
  }
}
