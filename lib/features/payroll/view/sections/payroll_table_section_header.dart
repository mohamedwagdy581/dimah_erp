import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/session/session_cubit.dart';
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

    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, sessionState) {
        final role = (sessionState as SessionReady).user.role;
        final isHr = role == 'hr' || role == 'admin';
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';

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
                _PayrollStatusFilter(cubit: cubit, state: state, isArabic: isArabic),
                _PayrollDateButton(
                  value: state.startDate,
                  icon: Icons.calendar_today_outlined,
                  emptyLabel: t.startFrom,
                  onPicked: cubit.startDateChanged,
                ),
                _PayrollDateButton(
                  value: state.endDate,
                  icon: Icons.calendar_month_outlined,
                  emptyLabel: t.endTo,
                  onPicked: cubit.endDateChanged,
                ),
                if (isHr) _NewPayrollRunButton(cubit: cubit),
                TextButton.icon(
                  onPressed: cubit.resetFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: Text(isArabic ? 'إعادة ضبط' : 'Reset'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PayrollStatusFilter extends StatelessWidget {
  const _PayrollStatusFilter({
    required this.cubit,
    required this.state,
    required this.isArabic,
  });

  final PayrollCubit cubit;
  final PayrollState state;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: state.status,
          onChanged: cubit.statusFilterChanged,
          hint: Text(t.all),
          items: [
            DropdownMenuItem(value: null, child: Text(t.all)),
            DropdownMenuItem(value: 'draft', child: Text(isArabic ? 'مسودة' : 'Draft')),
            DropdownMenuItem(
              value: 'pending_finance_manager',
              child: Text(isArabic ? 'بانتظار مدير المحاسبة' : 'Pending Finance Manager'),
            ),
            DropdownMenuItem(
              value: 'pending_admin_approval',
              child: Text(isArabic ? 'بانتظار الأدمن' : 'Pending Admin'),
            ),
            DropdownMenuItem(
              value: 'rejected_by_finance_manager',
              child: Text(isArabic ? 'مرفوض من مدير المحاسبة' : 'Rejected by Finance Manager'),
            ),
            DropdownMenuItem(
              value: 'rejected_by_admin',
              child: Text(isArabic ? 'مرفوض من الأدمن' : 'Rejected by Admin'),
            ),
            DropdownMenuItem(value: 'approved', child: Text(isArabic ? 'معتمد' : 'Approved')),
          ],
        ),
      ),
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
      icon: Icon(icon, size: 18),
      label: Text(value == null ? emptyLabel : _format(value!)),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  String _format(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
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
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
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
