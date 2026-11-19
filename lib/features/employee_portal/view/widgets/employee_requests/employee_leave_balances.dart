import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../leaves/domain/models/leave_balance.dart';
import '../../cubit/employee_leave_request_cubit.dart';

class EmployeeLeaveBalances extends StatelessWidget {
  const EmployeeLeaveBalances({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<EmployeeLeaveRequestCubit, EmployeeLeaveRequestState>(
    builder: (context, state) {
      final cubit = context.read<EmployeeLeaveRequestCubit>();
      final t = AppLocalizations.of(context)!;
      final ar = Localizations.localeOf(context).languageCode == 'ar';
      final cs = Theme.of(context).colorScheme;
      return Container(
        key: const ValueKey('employee-leave-balances'),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: .4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(
                  ar
                      ? 'رصيد إجازاتك · ${cubit.balanceYear}'
                      : 'Your leave balance · ${cubit.balanceYear}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('leave-balance-refresh'),
                  onPressed: state.loading || state.saving
                      ? null
                      : () => cubit.loadBalance(year: cubit.balanceYear),
                  icon: const Icon(Icons.refresh, size: 20),
                  label: Text(t.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.loading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                ar ? 'جارٍ تحديث رصيد الإجازات…' : 'Updating leave balances…',
              ),
            ] else if (state.balanceError != null)
              Text(
                ar
                    ? 'تعذّر تحميل الرصيد. اضغط تحديث للمحاولة مجددًا.'
                    : 'Unable to load balances. Refresh to try again.',
                style: TextStyle(color: cs.error),
              )
            else if (state.balances.isEmpty)
              Text(
                ar
                    ? 'لم يُسجّل رصيد إجازات لهذه السنة. تواصل مع الموارد البشرية.'
                    : 'No leave balance is recorded for this year. Contact HR.',
                style: TextStyle(color: cs.onSurfaceVariant),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                  final columns = (constraints.maxWidth / (260 * scale))
                      .floor()
                      .clamp(1, state.balances.length.clamp(1, 3));
                  final width =
                      (constraints.maxWidth - (columns - 1) * 12) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final balance in state.balances)
                        SizedBox(
                          width: width,
                          child: _BalanceCard(balance: balance),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      );
    },
  );
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});
  final LeaveBalance balance;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final cs = Theme.of(context).colorScheme;
    String number(double n) =>
        n == n.truncateToDouble() ? n.toInt().toString() : n.toStringAsFixed(1);
    final label = switch (balance.type) {
      'annual' => t.leaveTypeAnnual,
      'sick' => t.leaveTypeSick,
      'unpaid' => t.leaveTypeUnpaid,
      'other' => t.leaveTypeOther,
      _ => balance.type,
    };
    final color = balance.remaining < 0 ? cs.error : cs.primary;
    final progress = balance.entitlement > 0
        ? (balance.used / balance.entitlement).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      key: ValueKey('leave-balance-${balance.type}'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withValues(alpha: .14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            ar
                ? '${number(balance.remaining)} يوم متبقٍ'
                : '${number(balance.remaining)} days remaining',
            key: ValueKey('leave-remaining-${balance.type}'),
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            borderRadius: BorderRadius.circular(5),
            color: color,
            backgroundColor: cs.primary.withValues(alpha: .1),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 6,
            children: [
              Text(
                ar
                    ? 'المستحق: ${number(balance.entitlement)} يوم'
                    : 'Entitlement: ${number(balance.entitlement)} days',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              Text(
                ar
                    ? 'المستخدم: ${number(balance.used)} يوم'
                    : 'Used: ${number(balance.used)} days',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
