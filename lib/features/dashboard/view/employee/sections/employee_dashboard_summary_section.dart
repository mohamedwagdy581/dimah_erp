part of '../../dashboard_page.dart';

class _EmployeeSummarySection extends StatelessWidget {
  const _EmployeeSummarySection({required this.data});
  final EmployeeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final balance = data.annualBalance;
    String number(double value) => value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    final cards = [
      EmployeeStatCard(
        title: t.profileLeaveBalance,
        value: balance == null ? '—' : number(balance.remaining),
        subtitle: balance == null
            ? (ar ? 'الرصيد غير متاح' : 'Balance unavailable')
            : (ar
                  ? 'من ${number(balance.entitlement)} يوم • إجازة سنوية'
                  : 'of ${number(balance.entitlement)} days • Annual leave'),
        icon: Icons.calendar_month_outlined,
        color: const Color(0xFF009879),
        actionLabel: ar ? 'عرض التفاصيل' : 'View details',
        onTap: () => context.go('/my?tab=requests'),
      ),
      EmployeeStatCard(
        title: t.myRequests,
        value: '${data.pendingRequests}',
        subtitle: ar ? 'طلبات بانتظار الموافقة' : 'Requests awaiting approval',
        icon: Icons.description_outlined,
        color: const Color(0xFF1677FF),
        actionLabel: ar ? 'عرض الطلبات' : 'View requests',
        onTap: () => context.go('/my?tab=requests'),
      ),
      EmployeeStatCard(
        title: t.statusInProgress,
        value: '${data.inProgressTasks}',
        subtitle: ar ? 'مهام قيد التنفيذ' : 'Tasks in progress',
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFF59E0B),
        actionLabel: ar ? 'متابعة العمل' : 'Continue work',
        onTap: () => context.go('/my?tab=tasks'),
      ),
      EmployeeStatCard(
        title: ar ? 'مهامي اليوم' : 'My tasks today',
        value: '${data.todayTasks}',
        subtitle: ar ? 'مهام مستحقة اليوم' : 'Tasks due today',
        icon: Icons.assignment_outlined,
        color: const Color(0xFF009879),
        actionLabel: ar ? 'عرض المهام' : 'View tasks',
        onTap: () => context.go('/my?tab=tasks'),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 500
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }
}
