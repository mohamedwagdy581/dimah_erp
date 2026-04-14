import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/payroll_item.dart';
import '../cubit/payroll_run_cubit.dart';
import '../cubit/payroll_run_state.dart';

class PayrollRunItemsTable extends StatelessWidget {
  const PayrollRunItemsTable({super.key, required this.items});

  final List<PayrollItem> items;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(t.noPayrollItemsFound)),
        ),
      );
    }

    final totalBasic = items.fold<num>(0, (sum, r) => sum + r.basicSalary);
    final totalHousing = items.fold<num>(0, (sum, r) => sum + r.housingAllowance);
    final totalTransport = items.fold<num>(0, (sum, r) => sum + r.transportAllowance);
    final totalOther = items.fold<num>(0, (sum, r) => sum + r.otherAllowance);
    final totalAll = items.fold<num>(0, (sum, r) => sum + r.total);

    return BlocBuilder<PayrollRunCubit, PayrollRunState>(
      builder: (context, state) {
        final status = state.run?.status ?? 'draft';
        final rowColor = _getStatusRowColor(status);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: c.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                    columns: [
                      DataColumn(label: Text(t.employee, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(t.basic, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(t.housing, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(t.transport, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(t.other, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(t.total, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: [
                      ...items.map((r) {
                        return DataRow(
                          color: WidgetStateProperty.all(rowColor),
                          cells: [
                            DataCell(Text(r.employeeName)),
                            DataCell(Text(r.basicSalary.toStringAsFixed(2))),
                            DataCell(Text(r.housingAllowance.toStringAsFixed(2))),
                            DataCell(Text(r.transportAllowance.toStringAsFixed(2))),
                            DataCell(Text(r.otherAllowance.toStringAsFixed(2))),
                            DataCell(Text('${r.total.toStringAsFixed(2)} SAR',
                                style: const TextStyle(fontWeight: FontWeight.w600))),
                          ],
                        );
                      }),
                      DataRow(
                        color: WidgetStateProperty.all(Colors.grey.shade50),
                        cells: [
                          DataCell(Text(t.totalAllCaps, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(totalBasic.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(totalHousing.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(totalTransport.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(totalOther.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('${totalAll.toStringAsFixed(2)} SAR',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusRowColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green.withValues(alpha: 0.05);
      case 'rejected_by_finance_manager':
      case 'rejected_by_admin':
      case 'rejected':
        return Colors.red.withValues(alpha: 0.05);
      case 'pending_finance_manager':
      case 'pending_admin_approval':
        return Colors.orange.withValues(alpha: 0.05);
      default:
        return Colors.transparent;
    }
  }
}
