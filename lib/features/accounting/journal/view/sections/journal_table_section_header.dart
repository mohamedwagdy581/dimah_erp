import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../cubit/journal_cubit.dart';
import '../cubit/journal_state.dart';
import '../widgets/journal_form_dialog.dart';

class JournalTableSectionHeader extends StatelessWidget {
  const JournalTableSectionHeader({
    super.key,
    required this.cubit,
    required this.state,
  });

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
            _JournalStatusFilter(cubit: cubit, state: state),
            _JournalDateButton(
              value: state.startDate,
              icon: Icons.event,
              emptyLabel: t.startFrom,
              onPicked: cubit.startDateChanged,
            ),
            _JournalDateButton(
              value: state.endDate,
              icon: Icons.event_available,
              emptyLabel: t.endTo,
              onPicked: cubit.endDateChanged,
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
            _NewJournalEntryButton(cubit: cubit),
          ],
        ),
      ],
    );
  }
}

class _JournalStatusFilter extends StatelessWidget {
  const _JournalStatusFilter({
    required this.cubit,
    required this.state,
  });

  final JournalCubit cubit;
  final JournalState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return DropdownButton<String?>(
      value: state.status,
      onChanged: cubit.statusFilterChanged,
      items: [
        DropdownMenuItem(value: null, child: Text(t.all)),
        DropdownMenuItem(value: 'draft', child: Text(t.draft)),
        DropdownMenuItem(value: 'posted', child: Text(t.posted)),
      ],
    );
  }
}

class _JournalDateButton extends StatelessWidget {
  const _JournalDateButton({
    required this.value,
    required this.icon,
    required this.emptyLabel,
    required this.onPicked,
  });

  final DateTime? value;
  final IconData icon;
  final String emptyLabel;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _pick(context),
      icon: Icon(icon),
      label: Text(value == null ? emptyLabel : _formatDate(value!)),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  String _formatDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}

class _NewJournalEntryButton extends StatelessWidget {
  const _NewJournalEntryButton({required this.cubit});

  final JournalCubit cubit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ElevatedButton.icon(
      onPressed: () => _openDialog(context),
      icon: const Icon(Icons.add),
      label: Text(t.newEntry),
    );
  }

  Future<void> _openDialog(BuildContext context) async {
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
  }
}
