import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/payroll_cubit.dart';
import '../cubit/payroll_state.dart';
import '../widgets/payroll_run_dialog.dart';

class PayrollTableSectionHeader extends StatelessWidget {
  const PayrollTableSectionHeader({
    super.key,
    required this.cubit,
    required this.state,
  });

  final PayrollCubit cubit;
  final PayrollState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.menuPayroll,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _PayrollStatusFilter(cubit: cubit, state: state),
            _PayrollDateButton(
              value: state.startDate,
              icon: Icons.event,
              emptyLabel: t.startFrom,
              onPicked: cubit.startDateChanged,
            ),
            _PayrollDateButton(
              value: state.endDate,
              icon: Icons.event_available,
              emptyLabel: t.endTo,
              onPicked: cubit.endDateChanged,
            ),
            OutlinedButton.icon(
              onPressed: () => cubit.toggleSort('period_start'),
              icon: const Icon(Icons.schedule),
              label: Text(
                state.sortBy == 'period_start'
                    ? (state.ascending ? t.startAsc : t.startDesc)
                    : t.sortStart,
              ),
            ),
            _NewPayrollRunButton(cubit: cubit),
          ],
        ),
      ],
    );
  }
}

class _PayrollStatusFilter extends StatelessWidget {
  const _PayrollStatusFilter({required this.cubit, required this.state});

  final PayrollCubit cubit;
  final PayrollState state;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return DropdownButton<String?>(
      value: state.status,
      onChanged: cubit.statusFilterChanged,
      items: [
        DropdownMenuItem(value: null, child: Text(t.all)),
        DropdownMenuItem(value: 'draft', child: Text(t.draft)),
        DropdownMenuItem(value: 'finalized', child: Text(t.finalized)),
      ],
    );
  }
}

class _PayrollDateButton extends StatelessWidget {
  const _PayrollDateButton({
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
      label: Text(value == null ? emptyLabel : _format(value!)),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  String _format(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}

class _NewPayrollRunButton extends StatelessWidget {
  const _NewPayrollRunButton({required this.cubit});

  final PayrollCubit cubit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ElevatedButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.add),
      label: Text(t.newPayrollRun),
    );
  }

  Future<void> _open(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<PayrollCubit>(),
        child: const PayrollRunDialog(),
      ),
    );
    if (ok == true && context.mounted) {
      cubit.load(resetPage: true);
    }
  }
}
