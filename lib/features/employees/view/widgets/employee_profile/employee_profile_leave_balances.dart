import 'package:flutter/material.dart';
import 'package:erp_sys/core/ui/app_data_state.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../leaves/domain/models/leave_balance.dart';

class EmployeeProfileLeaveBalances extends StatelessWidget {
  const EmployeeProfileLeaveBalances({super.key, required this.balances});
  final List<LeaveBalance> balances;
  static const purple = Color(0xFF8659BB);
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String a, String e) => ar ? a : e;
    String number(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
    if (balances.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: AppEmptyState(
          title: tr(
            'لا توجد أرصدة إجازات مسجلة لهذا العام.',
            'No leave balances recorded for this year.',
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 900
            ? 3
            : box.maxWidth >= 550
            ? 2
            : 1;
        final width = (box.maxWidth - 14 * (columns - 1)) / columns;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final b in balances)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFECE7F5)),
                    color: const Color(0xFFFDFCFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: purple.withValues(alpha: .09),
                            child: Icon(
                              b.type == 'annual'
                                  ? Icons.beach_access_outlined
                                  : b.type == 'sick'
                                  ? Icons.health_and_safety_outlined
                                  : Icons.event_available_outlined,
                              color: purple,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              switch (b.type) {
                                'annual' => t.leaveTypeAnnual,
                                'sick' => t.leaveTypeSick,
                                'other' => t.leaveTypeOther,
                                _ => b.type,
                              },
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF24204E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        tr('الرصيد المتبقي', 'Remaining balance'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF66638B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            number(b.remaining),
                            style: TextStyle(
                              fontSize: 30,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              color: b.remaining < 0
                                  ? const Color(0xFFD7193F)
                                  : purple,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tr('يوم', 'days'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF66638B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        tr('استخدام الرصيد', 'Balance usage'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF66638B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: b.entitlement > 0
                              ? (b.used / b.entitlement).clamp(0, 1)
                              : 0,
                          minHeight: 6,
                          color: purple,
                          backgroundColor: const Color(0xFFEDE5F6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          Text(
                            t.entitlementWithValue(number(b.entitlement)),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF66638B),
                            ),
                          ),
                          Text(
                            t.usedWithValue(number(b.used)),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF66638B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
