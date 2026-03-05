import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/job_title.dart';

class JobTitlesTable extends StatelessWidget {
  const JobTitlesTable({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onToggleActive,
  });

  final List<JobTitle> items;
  final Future<void> Function(JobTitle jt) onEdit;
  final void Function(JobTitle jt) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(t.noJobTitlesFound)),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            DataColumn(label: Text(t.name)),
            DataColumn(label: Text(t.code)),
            DataColumn(label: Text(t.level)),
            DataColumn(label: Text(t.status)),
            DataColumn(label: Text(t.actions)),
          ],
          rows: items.map((jt) {
            return DataRow(
              cells: [
                DataCell(Text(jt.name)),
                DataCell(Text(jt.code ?? '-')),
                DataCell(Text(jt.level?.toString() ?? '-')),
                DataCell(Text(jt.isActive ? t.active : t.inactive)),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: t.edit,
                        onPressed: () => onEdit(jt),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        tooltip: jt.isActive ? t.disable : t.enable,
                        onPressed: () => onToggleActive(jt),
                        icon: Icon(
                          jt.isActive ? Icons.block : Icons.check_circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
