import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/department.dart';

class DepartmentTable extends StatelessWidget {
  const DepartmentTable({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onToggleActive,
  });

  final List<Department> items;
  final ValueChanged<Department> onEdit;
  final ValueChanged<Department> onToggleActive;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(t.noDepartmentsFound)),
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
                  DataColumn(label: Text(t.name)),
                  DataColumn(label: Text(t.code)),
                  DataColumn(label: Text(t.manager)),
                  DataColumn(label: Text(t.status)),
                  DataColumn(label: Text(t.actions)),
                ],
                rows: items.map((d) {
                  return DataRow(
                    cells: [
                      DataCell(Text(d.name)),
                      DataCell(Text(d.code ?? '-')),
                      DataCell(Text((d.managerName ?? '').trim().isEmpty ? '-' : d.managerName!)),
                      DataCell(Text(d.isActive ? t.active : t.inactive)),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              tooltip: t.edit,
                              onPressed: () => onEdit(d),
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              tooltip: d.isActive ? t.disable : t.enable,
                              onPressed: () => onToggleActive(d),
                              icon: Icon(
                                d.isActive ? Icons.block : Icons.check_circle,
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
        },
      ),
    );
  }
}
