import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:material_ui/material_ui.dart';
import 'payroll_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/payroll_item.dart';

class PayrollRunItemsTable extends StatelessWidget {
  const PayrollRunItemsTable({
    super.key,
    required this.items,
    this.compact = false,
  });
  final List<PayrollItem> items;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: AppEmptyState(title: t.noPayrollItemsFound, compact: false),
      );
    }
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: c.maxWidth),
          child: DataTable(
            headingRowHeight: 42,
            dataRowMinHeight: compact ? 42 : 54,
            dataRowMaxHeight: compact ? 54 : 70,
            horizontalMargin: 12,
            columnSpacing: 24,
            border: const TableBorder(
              horizontalInside: BorderSide(color: Color(0xFFF0ECF5)),
              verticalInside: BorderSide(color: Color(0xFFF4F1F8)),
            ),
            dividerThickness: 0,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F6FB)),
            headingTextStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF55506F),
              fontSize: compact ? 15 : 12,
              fontWeight: FontWeight.w600,
            ),
            dataTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF21194E),
              fontSize: compact ? 14 : 12,
            ),
            columns: [
              for (final label in [
                t.employee,
                ar ? 'المسمى الوظيفي' : 'Job title',
                compact && ar ? 'الراتب الأساسي' : t.basic,
                compact && ar ? 'بدل السكن' : t.housing,
                compact && ar ? 'بدل النقل' : t.transport,
                compact && ar ? 'بدلات أخرى' : t.other,
                t.total,
              ])
                DataColumn(label: Text(label)),
            ],
            rows: [
              for (final r in items)
                DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: r.photoUrl?.isNotEmpty == true
                                  ? Image.network(
                                      r.photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, error, stack) =>
                                          _initials(r.employeeName),
                                    )
                                  : _initials(r.employeeName),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 180,
                            child: Text(
                              r.employeeName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 135,
                        child: Text(
                          r.jobTitle.isEmpty ? '?' : r.jobTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    for (final value in [
                      r.basicSalary,
                      r.housingAllowance,
                      r.transportAllowance,
                      r.otherAllowance,
                      r.total,
                    ])
                      DataCell(
                        Text(
                          payrollMoney(value),
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initials(String name) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p.characters.first)
        .join();
    return Container(
      color: const Color(0xFFF0E5FC),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(
          color: Color(0xFF8659BB),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
