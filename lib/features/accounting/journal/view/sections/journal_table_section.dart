import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../cubit/journal_cubit.dart';
import '../cubit/journal_state.dart';
import '../widgets/journal_form_dialog.dart';
import '../widgets/journal_pagination_bar.dart';
import '../widgets/journal_table.dart';

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
              _Header(cubit: cubit, state: state),
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

class _Header extends StatelessWidget {
  const _Header({required this.cubit, required this.state});

  final JournalCubit cubit;
  final JournalState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.menuJournal,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String?>(
              value: state.status,
              onChanged: (v) => cubit.statusFilterChanged(v),
              items: [
                DropdownMenuItem(value: null, child: Text(t.all)),
                DropdownMenuItem(value: 'draft', child: Text(t.draft)),
                DropdownMenuItem(value: 'posted', child: Text(t.posted)),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.startDate ?? now,
                  firstDate: DateTime(now.year - 1, 1, 1),
                  lastDate: DateTime(now.year + 1, 12, 31),
                );
                if (picked != null) {
                  cubit.startDateChanged(picked);
                }
              },
              icon: const Icon(Icons.event),
              label: Text(
                state.startDate == null
                    ? t.startFrom
                    : '${state.startDate!.year.toString().padLeft(4, '0')}-'
                        '${state.startDate!.month.toString().padLeft(2, '0')}-'
                        '${state.startDate!.day.toString().padLeft(2, '0')}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.endDate ?? now,
                  firstDate: DateTime(now.year - 1, 1, 1),
                  lastDate: DateTime(now.year + 1, 12, 31),
                );
                if (picked != null) {
                  cubit.endDateChanged(picked);
                }
              },
              icon: const Icon(Icons.event_available),
              label: Text(
                state.endDate == null
                    ? t.endTo
                    : '${state.endDate!.year.toString().padLeft(4, '0')}-'
                        '${state.endDate!.month.toString().padLeft(2, '0')}-'
                        '${state.endDate!.day.toString().padLeft(2, '0')}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => cubit.toggleSort('entry_date'),
              icon: const Icon(Icons.schedule),
              label: Text(
                state.sortBy == 'entry_date'
                    ? (state.ascending ? t.dateAsc : t.dateDesc)
                    : t.sortDate,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: context.read<JournalCubit>(),
                    child: const JournalFormDialog(),
                  ),
                );
                if (ok == true && context.mounted) {
                  cubit.load(resetPage: true);
                }
              },
              icon: const Icon(Icons.add),
              label: Text(t.newEntry),
            ),
          ],
        ),
      ],
    );
  }
}
