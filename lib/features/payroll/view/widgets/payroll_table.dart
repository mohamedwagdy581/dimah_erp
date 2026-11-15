import 'dart:math' as math;
import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/payroll_run.dart';
import 'payroll_format.dart';

class PayrollTable extends StatefulWidget {
  const PayrollTable({super.key, required this.items, required this.onOpenRun});
  final List<PayrollRun> items;
  final ValueChanged<String> onOpenRun;
  @override
  State<PayrollTable> createState() => _PayrollTableState();
}

class _PayrollTableState extends State<PayrollTable> {
  final _horizontal = ScrollController();
  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (widget.items.isEmpty) {
      return AppEmptyState(title: t.noPayrollRunsFound, compact: false);
    }
    final labels = [
      t.periodStart,
      t.periodEnd,
      t.status,
      t.employeesCount,
      t.totalAmount,
      t.actions,
    ];
    Widget cell(Widget child, {bool heading = false}) => Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: heading ? 18 : 16,
      ),
      child: Center(
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: const Color(0xFF21194E),
            fontSize: heading ? 13 : 14,
            height: 1.5,
            fontWeight: heading ? FontWeight.w700 : FontWeight.w500,
          ),
          child: child,
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, box) {
        final width = math.max(1030.0, box.maxWidth);
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5DDF2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Scrollbar(
            controller: _horizontal,
            thumbVisibility: true,
            notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SingleChildScrollView(
                controller: _horizontal,
                key: const ValueKey('payroll-list-horizontal-scroll'),
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1.65),
                      3: FlexColumnWidth(1),
                      4: FlexColumnWidth(1.15),
                      5: FlexColumnWidth(1),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: const TableBorder(
                      horizontalInside: BorderSide(color: Color(0xFFEDE7F5)),
                    ),
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F1FA),
                        ),
                        children: labels
                            .map((label) => cell(Text(label), heading: true))
                            .toList(),
                      ),
                      for (final entry in widget.items.indexed)
                        TableRow(
                          decoration: BoxDecoration(
                            color: entry.$1.isEven
                                ? Colors.white
                                : const Color(0xFFFCFAFF),
                          ),
                          children: [
                            cell(
                              Text(
                                payrollDate(entry.$2.periodStart),
                                textDirection: TextDirection.ltr,
                              ),
                            ),
                            cell(
                              Text(
                                payrollDate(entry.$2.periodEnd),
                                textDirection: TextDirection.ltr,
                              ),
                            ),
                            cell(_buildStatusChip(context, entry.$2.status)),
                            cell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.people_outline,
                                    size: 18,
                                    color: Color(0xFF9B74BF),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(entry.$2.totalEmployees.toString()),
                                ],
                              ),
                            ),
                            cell(
                              Text(
                                payrollMoney(entry.$2.totalAmount),
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            cell(
                              OutlinedButton.icon(
                                key: ValueKey('open-payroll-${entry.$2.id}'),
                                onPressed: () => widget.onOpenRun(entry.$2.id),
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  t.view,
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF8659BB),
                                  backgroundColor: const Color(0xFFFBF8FF),
                                  side: const BorderSide(
                                    color: Color(0xFFE5D8F4),
                                  ),
                                  minimumSize: const Size(110, 40),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final color = _getStatusColor(status);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _labelForStatus(status, isArabic),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _labelForStatus(String status, bool isArabic) {
    switch (status) {
      case 'draft':
        return isArabic ? 'مسودة' : 'Draft';
      case 'pending_finance_manager':
        return isArabic ? 'بانتظار مدير المحاسبة' : 'Pending Finance Manager';
      case 'pending_admin_approval':
        return isArabic ? 'بانتظار الأدمن' : 'Pending Admin';
      case 'rejected_by_finance_manager':
        return isArabic
            ? 'مرفوض من مدير المحاسبة'
            : 'Rejected by Finance Manager';
      case 'rejected_by_admin':
        return isArabic ? 'مرفوض من الأدمن' : 'Rejected by Admin';
      case 'approved':
        return isArabic ? 'معتمد' : 'Approved';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF009B7E);
      case 'rejected_by_finance_manager':
      case 'rejected_by_admin':
      case 'rejected':
        return const Color(0xFFF04461);
      case 'pending_finance_manager':
      case 'pending_admin_approval':
        return const Color(0xFFF08C00);
      default:
        return const Color(0xFF8659BB);
    }
  }
}
