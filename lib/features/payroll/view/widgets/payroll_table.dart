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
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(t.noPayrollRunsFound)),
        ),
      );
    }

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
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                dataRowMaxHeight: 60,
                columns: [
                  DataColumn(label: Text(t.periodStart, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(t.periodEnd, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(t.status, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(t.employeesCount, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(t.totalAmount, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(t.actions, style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: items.map((r) {
                  final statusColor = _getStatusColor(r.status);
                  return DataRow(
                    color: WidgetStateProperty.all(statusColor.withValues(alpha: 0.05)),
                    cells: [
                      DataCell(Text(_formatDate(r.periodStart))),
                      DataCell(Text(_formatDate(r.periodEnd))),
                      DataCell(_buildStatusChip(context, r.status)),
                      DataCell(Text(r.totalEmployees.toString())),
                      DataCell(Text('${r.totalAmount.toStringAsFixed(2)} SAR',
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(
                        ElevatedButton(
                          onPressed: () => onOpenRun(r.id),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
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

  Widget _buildStatusChip(BuildContext context, String status) {
    final color = _getStatusColor(status);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Chip(
      label: Text(
        _labelForStatus(status, isArabic),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
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
        return isArabic ? 'مرفوض من مدير المحاسبة' : 'Rejected by Finance Manager';
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
        return Colors.green.shade600;
      case 'rejected_by_finance_manager':
      case 'rejected_by_admin':
      case 'rejected':
        return Colors.red.shade600;
      case 'pending_finance_manager':
      case 'pending_admin_approval':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
