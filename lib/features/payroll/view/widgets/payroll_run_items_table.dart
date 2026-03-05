import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/payroll_item.dart';

class PayrollRunItemsTable extends StatelessWidget {
  const PayrollRunItemsTable({super.key, required this.items});

  final List<PayrollItem> items;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text(t.noPayrollItemsFound)),
        ),
      );
    }

    final totalBasic = items.fold<num>(0, (sum, r) => sum + r.basicSalary);
    final totalHousing = items.fold<num>(0, (sum, r) => sum + r.housingAllowance);
    final totalTransport = items.fold<num>(0, (sum, r) => sum + r.transportAllowance);
    final totalOther = items.fold<num>(0, (sum, r) => sum + r.otherAllowance);
    final totalAll = items.fold<num>(0, (sum, r) => sum + r.total);

    return Card(
      child: LayoutBuilder(
        builder: (context, c) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: c.maxWidth),
              child: DataTable(
                columns: [
                  DataColumn(label: Text(t.employee)),
                  DataColumn(label: Text(t.basic)),
                  DataColumn(label: Text(t.housing)),
                  DataColumn(label: Text(t.transport)),
                  DataColumn(label: Text(t.other)),
                  DataColumn(label: Text(t.total)),
                ],
                rows: [
                  ...items.map((r) {
                    return DataRow(
                      cells: [
                        DataCell(Text(r.employeeName)),
                        DataCell(Text(r.basicSalary.toStringAsFixed(2))),
                        DataCell(Text(r.housingAllowance.toStringAsFixed(2))),
                        DataCell(Text(r.transportAllowance.toStringAsFixed(2))),
                        DataCell(Text(r.otherAllowance.toStringAsFixed(2))),
                        DataCell(Text(r.total.toStringAsFixed(2))),
                      ],
                    );
                  }),
                  DataRow(
                    cells: [
                      DataCell(
                        Text(
                          t.totalAllCaps,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      DataCell(
                        Text(
                          totalBasic.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      DataCell(
                        Text(
                          totalHousing.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      DataCell(
                        Text(
                          totalTransport.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      DataCell(
                        Text(
                          totalOther.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      DataCell(
                        Text(
                          totalAll.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
