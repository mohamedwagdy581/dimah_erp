import 'package:go_router/go_router.dart';
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
        if (sessionState is! SessionReady) return const SizedBox.shrink();
        final role = sessionState.user.role;
        final isHr = role == 'hr' || role == 'admin';
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final heading = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1E6FC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFF8659BB),
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'مسيرات الرواتب' : 'Payroll runs',
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF21194E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isArabic
                                ? 'تجهيز الرواتب ومتابعة المراجعة والاعتماد'
                                : 'Prepare payroll and track review and approval',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF77738C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                return constraints.maxWidth >= 650
                    ? Row(
                        children: [
                          Expanded(child: heading),
                          const SizedBox(width: 16),
                          _HeaderActions(
                            cubit: cubit,
                            isHr: isHr,
                            loading: state.loading,
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          heading,
                          const SizedBox(height: 12),
                          _HeaderActions(
                            cubit: cubit,
                            isHr: isHr,
                            loading: state.loading,
                          ),
                        ],
                      );
              },
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFAFF),
                border: Border.all(color: const Color(0xFFEAE3F2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _PayrollStatusFilter(
                    cubit: cubit,
                    state: state,
                    isArabic: isArabic,
                  ),
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
                  TextButton.icon(
                    onPressed: state.loading ? null : cubit.resetFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: Text(isArabic ? 'إعادة ضبط' : 'Reset'),
                  ),
                ],
              ),
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
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5DCF0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: state.status,
          onChanged: state.loading ? null : cubit.statusFilterChanged,
          hint: Text(t.all),
          items: [
            DropdownMenuItem(value: null, child: Text(t.all)),
            DropdownMenuItem(
              value: 'draft',
              child: Text(isArabic ? 'مسودة' : 'Draft'),
            ),
            DropdownMenuItem(
              value: 'pending_finance_manager',
              child: Text(
                isArabic ? 'بانتظار مدير المحاسبة' : 'Pending Finance Manager',
              ),
            ),
            DropdownMenuItem(
              value: 'pending_admin_approval',
              child: Text(isArabic ? 'بانتظار الأدمن' : 'Pending Admin'),
            ),
            DropdownMenuItem(
              value: 'rejected_by_finance_manager',
              child: Text(
                isArabic
                    ? 'مرفوض من مدير المحاسبة'
                    : 'Rejected by Finance Manager',
              ),
            ),
            DropdownMenuItem(
              value: 'rejected_by_admin',
              child: Text(isArabic ? 'مرفوض من الأدمن' : 'Rejected by Admin'),
            ),
            DropdownMenuItem(
              value: 'approved',
              child: Text(isArabic ? 'معتمد' : 'Approved'),
            ),
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
        minimumSize: const Size(160, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        foregroundColor: const Color(0xFF8659BB),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE5DCF0)),
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

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({
    required this.cubit,
    required this.isHr,
    required this.loading,
  });
  final PayrollCubit cubit;
  final bool isHr, loading;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (isHr) _NewPayrollRunButton(cubit: cubit),
      IconButton.outlined(
        tooltip: Localizations.localeOf(context).languageCode == 'ar'
            ? 'تحديث المسيرات'
            : 'Refresh payroll',
        onPressed: loading ? null : cubit.load,
        icon: const Icon(Icons.refresh_rounded),
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: const Color(0xFF8659BB),
          side: const BorderSide(color: Color(0xFFE5DCF0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ],
  );
}

class _NewPayrollRunButton extends StatelessWidget {
  const _NewPayrollRunButton({required this.cubit});

  final PayrollCubit cubit;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: cubit.state.loading ? null : () => _open(context),
      icon: const Icon(Icons.add),
      label: Text(
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'تجهيز مسير جديد'
            : 'Prepare new payroll',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9B74BF),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final id = await showDialog<String>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<PayrollCubit>(),
        child: const PayrollRunDialog(),
      ),
    );
    if (id != null && context.mounted) {
      context.go('/payroll/$id');
    }
  }
}
