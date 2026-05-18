import 'package:flutter/material.dart';

import '../../../../../core/di/app_di.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../leaves/domain/models/leave_balance.dart';
import '../../../../leaves/view/sections/leaves_balance_cards.dart';
import '../../../domain/models/employee_profile_details.dart';
import '../../utils/employee_profile_utils.dart';
import 'profile_section_card.dart';

class EmployeeProfileLeaveSection extends StatelessWidget {
  const EmployeeProfileLeaveSection({
    super.key,
    required this.profile,
  });

  final EmployeeProfileDetails profile;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return FutureBuilder<List<LeaveBalance>>(
      future: AppDI.leavesRepo.fetchLeaveBalances(
        employeeId: profile.id,
        year: DateTime.now().year,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ProfileSectionCard(
            title: t.profileLeaveBalance,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return ProfileSectionCard(
            title: t.profileLeaveBalance,
            children: [
              Text(
                t.leaveBalanceLoadFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
          children: [
            _LeaveEligibilityBanner(status: eligibility),
            const SizedBox(height: 12),
            LeavesBalanceCards(balances: balances, t: t),
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
        message: t.leaveBalanceLoadFailed,
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
          formatEmployeeDate(eligibilityDate),
        ),
        backgroundColor: Colors.green.withValues(alpha: 0.12),
        foregroundColor: Colors.green.shade800,
        icon: annualBalance.remaining > 0
            ? Icons.celebration_outlined
            : Icons.event_busy_outlined,
      );
    }

    return _LeaveEligibilityStatus(
      message: t.annualLeaveAvailableOn(formatEmployeeDate(eligibilityDate)),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(status.icon, color: status.foregroundColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status.message,
              style: TextStyle(
                color: status.foregroundColor,
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
