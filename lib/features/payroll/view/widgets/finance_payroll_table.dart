import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../../domain/models/payroll_item.dart';
import 'payroll_format.dart';

const financeNavy = Color(0xFF19144F);
const financePurple = Color(0xFF8855BF);
const financeBorder = Color(0xFFE8DFFA);

/// One shared column layout for headings, salary rows and totals.
class FinancePayrollTable extends StatefulWidget {
  const FinancePayrollTable({super.key, required this.items});
  final List<PayrollItem> items;
  @override
  State<FinancePayrollTable> createState() => _FinancePayrollTableState();
}

class _FinancePayrollTableState extends State<FinancePayrollTable> {
  final _horizontal = ScrollController();
  final _vertical = ScrollController();
  static const _weights = [26, 23, 15, 12, 12, 12, 15];
  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  Widget _row(List<Widget> cells, {Color? color, double height = 52}) =>
      Container(
        constraints: BoxConstraints(minHeight: height),
        decoration: BoxDecoration(
          color: color,
          border: const Border(bottom: BorderSide(color: financeBorder)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < cells.length; i++)
              Expanded(
                flex: _weights[i],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: cells[i],
                ),
              ),
          ],
        ),
      );

  Widget _text(
    String value, {
    bool bold = false,
    double size = 14,
    bool money = false,
  }) => Text(
    value,
    textAlign: TextAlign.center,
    textDirection: money ? TextDirection.ltr : null,
    style: TextStyle(
      color: financeNavy,
      fontSize: size,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final titles = ar
        ? [
            'الموظف',
            'المسمى الوظيفي',
            'الراتب الأساسي',
            'بدل السكن',
            'بدل النقل',
            'بدلات أخرى',
            'إجمالي الراتب',
          ]
        : [
            'Employee',
            'Job title',
            'Basic salary',
            'Housing',
            'Transport',
            'Other',
            'Total salary',
          ];
    final totals = List<num>.filled(5, 0);
    for (final item in widget.items) {
      final values = [
        item.basicSalary,
        item.housingAllowance,
        item.transportAllowance,
        item.otherAllowance,
        item.total,
      ];
      for (var i = 0; i < values.length; i++) {
        totals[i] += values[i];
      }
    }
    return LayoutBuilder(
      builder: (context, bounds) => Scrollbar(
        controller: _vertical,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: financeBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Scrollbar(
            controller: _horizontal,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              key: const ValueKey('finance-table-scroll'),
              controller: _horizontal,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: math.max(1060, bounds.maxWidth - 2),
                height: math
                    .min(520, 128 + widget.items.length * 60)
                    .toDouble(),
                child: Column(
                  children: [
                    _row(
                      titles
                          .map((s) => _text(s, bold: true, size: 15))
                          .toList(),
                      color: const Color(0xFFF6F5FC),
                      height: 48,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        key: const ValueKey('finance-table-vertical-scroll'),
                        controller: _vertical,
                        child: Column(
                          children: [
                            for (final item in widget.items)
                              _row([
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 17,
                                      backgroundColor: const Color(0xFFF0E3FF),
                                      child: Text(
                                        item.employeeName.trim().isEmpty
                                            ? '—'
                                            : item.employeeName
                                                  .trim()
                                                  .characters
                                                  .first,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: financePurple,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Tooltip(
                                        message: item.employeeName,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.employeeName,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: financeNavy,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (item
                                                    .employeeNumber
                                                    ?.isNotEmpty ==
                                                true)
                                              Text(
                                                item.employeeNumber!,
                                                textDirection:
                                                    TextDirection.ltr,
                                                style: const TextStyle(
                                                  color: Color(0xFF77709A),
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Tooltip(
                                  message: item.jobTitle,
                                  child: _text(
                                    item.jobTitle.isEmpty ? '—' : item.jobTitle,
                                  ),
                                ),
                                for (final value in [
                                  item.basicSalary,
                                  item.housingAllowance,
                                  item.transportAllowance,
                                  item.otherAllowance,
                                ])
                                  _text(payrollMoney(value), money: true),
                                _text(
                                  payrollMoney(item.total),
                                  bold: true,
                                  money: true,
                                ),
                              ]),
                          ],
                        ),
                      ),
                    ),
                    _row(
                      [
                        _text(ar ? 'الإجمالي' : 'Total', bold: true, size: 18),
                        const SizedBox.shrink(),
                        for (final total in totals)
                          _text(
                            payrollMoney(total),
                            bold: true,
                            size: 18,
                            money: true,
                          ),
                      ],
                      color: const Color(0xFFE9DDFB),
                      height: 50,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
