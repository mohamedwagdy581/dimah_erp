import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/payroll_run.dart';

class PayrollTable extends StatelessWidget {
  const PayrollTable({
    super.key,
    required this.items,
    required this.onOpenRun,
  });

  final List<PayrollRun> items;
  final ValueChanged<String> onOpenRun;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text(t.noPayrollRunsFound)),
        ),
      );
    }

    return Card(
      child: LayoutBuilder(
        builder: (context, c) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: c.maxWidth),
              child: DataTable(
                columns: [
                  DataColumn(label: Text(t.periodStart)),
                  DataColumn(label: Text(t.periodEnd)),
                  DataColumn(label: Text(t.status)),
                  DataColumn(label: Text(t.employeesCount)),
                  DataColumn(label: Text(t.totalAmount)),
                  DataColumn(label: Text(t.created)),
                  DataColumn(label: Text(t.actions)),
                ],
                rows: items.map((r) {
                  return DataRow(
                    cells: [
                      DataCell(Text(_formatDate(r.periodStart))),
                      DataCell(Text(_formatDate(r.periodEnd))),
                      DataCell(Text(r.status)),
                      DataCell(Text(r.totalEmployees.toString())),
                      DataCell(Text(r.totalAmount.toStringAsFixed(2))),
                      DataCell(Text(_formatDate(r.createdAt))),
                      DataCell(
                        TextButton(
                          onPressed: () => onOpenRun(r.id),
                          child: Text(t.view),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}
