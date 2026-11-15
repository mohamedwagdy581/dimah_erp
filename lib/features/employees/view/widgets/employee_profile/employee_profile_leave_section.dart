import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';

import '../../../../../core/di/app_di.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../leaves/domain/models/leave_balance.dart';
import 'employee_profile_leave_balances.dart';
import '../../../domain/models/employee_profile_details.dart';
import '../../utils/employee_profile_utils.dart';
import 'profile_section_card.dart';

class EmployeeProfileLeaveSection extends StatefulWidget {
  const EmployeeProfileLeaveSection({
    super.key,
    required this.profile,
    this.balancesFuture,
    this.loadBalances,
  });

  final EmployeeProfileDetails profile;
  final Future<List<LeaveBalance>>? balancesFuture;
  final Future<List<LeaveBalance>> Function()? loadBalances;

  @override
  State<EmployeeProfileLeaveSection> createState() =>
      _EmployeeProfileLeaveSectionState();
}

class _EmployeeProfileLeaveSectionState
    extends State<EmployeeProfileLeaveSection> {
  late Future<List<LeaveBalance>> _future;
  EmployeeProfileDetails get profile => widget.profile;
  Future<List<LeaveBalance>> _load() =>
      widget.loadBalances?.call() ??
      AppDI.leavesRepo.fetchLeaveBalances(
        employeeId: profile.id,
        year: DateTime.now().year,
      );
  @override
  void initState() {
    super.initState();
    _future = widget.balancesFuture ?? _load();
  }

  @override
  void didUpdateWidget(covariant EmployeeProfileLeaveSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.id != profile.id ||
        oldWidget.balancesFuture != widget.balancesFuture ||
        oldWidget.loadBalances != widget.loadBalances) {
      _future = widget.balancesFuture ?? _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return FutureBuilder<List<LeaveBalance>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ProfileSectionCard(
            title: t.profileLeaveBalance,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: AppLoadingState(),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return ProfileSectionCard(
            title: t.profileLeaveBalance,
            children: [
              AppFailureState(
                error: snapshot.error,
                onRetry: () => setState(() => _future = _load()),
              ),
            ],
          );
        }

        final balances = snapshot.data ?? const <LeaveBalance>[];
        final annualBalance = _annualBalanceOf(balances);
        final eligibility = _buildEligibilityStatus(
          context: context,
          annualBalance: annualBalance,
        );

        return ProfileSectionCard(
          title: t.profileLeaveBalance,
          trailing: Text(
            '${DateTime.now().year}',
            style: const TextStyle(
              color: Color(0xFF8659BB),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            _LeaveEligibilityBanner(status: eligibility),
            const SizedBox(height: 12),
            EmployeeProfileLeaveBalances(balances: balances),
          ],
        );
      },
    );
  }

  LeaveBalance _annualBalanceOf(List<LeaveBalance> balances) {
    for (final balance in balances) {
      if (balance.type == 'annual') {
        return balance;
      }
    }
    return const LeaveBalance(type: 'annual', entitlement: 0, used: 0);
  }

  _LeaveEligibilityStatus _buildEligibilityStatus({
    required BuildContext context,
    required LeaveBalance annualBalance,
  }) {
    final t = AppLocalizations.of(context)!;
    final hireDate = profile.hireDate;

    if (hireDate == null) {
      return _LeaveEligibilityStatus(
        message: Localizations.localeOf(context).languageCode == 'ar'
            ? 'أضف تاريخ التعيين لعرض موعد استحقاق الإجازة السنوية.'
            : 'Add the hire date to show annual leave eligibility.',
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        icon: Icons.info_outline,
      );
    }

    final eligibilityDate = _addMonthsClamped(
      DateTime(hireDate.year, hireDate.month, hireDate.day),
      11,
    );
    final today = DateTime.now();
    final isEligible = !DateTime(
      today.year,
      today.month,
      today.day,
    ).isBefore(eligibilityDate);

    if (isEligible) {
      return _LeaveEligibilityStatus(
        message: t.annualLeaveEligibleSince(
          formatEmployeeDate(eligibilityDate).replaceAll('-', '/'),
        ),
        backgroundColor: const Color(0xFFF6F0FC),
        foregroundColor: const Color(0xFF8659BB),
        icon: annualBalance.remaining > 0
            ? Icons.celebration_outlined
            : Icons.event_busy_outlined,
      );
    }

    return _LeaveEligibilityStatus(
      message: t.annualLeaveAvailableOn(
        formatEmployeeDate(eligibilityDate).replaceAll('-', '/'),
      ),
      backgroundColor: Colors.orange.withValues(alpha: 0.14),
      foregroundColor: Colors.orange.shade900,
      icon: Icons.schedule_outlined,
    );
  }

  DateTime _addMonthsClamped(DateTime value, int monthsToAdd) {
    final monthIndex = value.month - 1 + monthsToAdd;
    final targetYear = value.year + (monthIndex ~/ 12);
    final targetMonth = (monthIndex % 12) + 1;
    final maxDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = value.day <= maxDay ? value.day : maxDay;
    return DateTime(targetYear, targetMonth, targetDay);
  }
}

class _LeaveEligibilityBanner extends StatelessWidget {
  const _LeaveEligibilityBanner({required this.status});

  final _LeaveEligibilityStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: status.foregroundColor.withValues(alpha: .14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(status.icon, color: status.foregroundColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status.message,
              style: TextStyle(
                color: status.foregroundColor,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveEligibilityStatus {
  const _LeaveEligibilityStatus({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
}
