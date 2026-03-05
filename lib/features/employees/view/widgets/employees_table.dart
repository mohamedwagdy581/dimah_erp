import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/employee.dart';

class EmployeesTable extends StatefulWidget {
  const EmployeesTable({
    super.key,
    required this.items,
    this.canOpenProfile = true,
  });

  final List<Employee> items;
  final bool canOpenProfile;

  @override
  State<EmployeesTable> createState() => _EmployeesTableState();
}

class _EmployeesTableState extends State<EmployeesTable> {
  final ScrollController _vertical = ScrollController();
  final ScrollController _horizontal = ScrollController();

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (widget.items.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text(t.noEmployeesFound)),
        ),
      );
    }

    return Card(
      child: LayoutBuilder(
        builder: (context, c) {
          return ScrollbarTheme(
            data: ScrollbarThemeData(
              thumbVisibility: WidgetStateProperty.all(true),
              trackVisibility: WidgetStateProperty.all(true),
              thickness: WidgetStateProperty.all(8),
              radius: const Radius.circular(6),
            ),
            child: Scrollbar(
              thumbVisibility: true,
              controller: _vertical,
              scrollbarOrientation: ScrollbarOrientation.right,
              child: SingleChildScrollView(
                controller: _vertical,
                primary: false,
                scrollDirection: Axis.vertical,
                child: Scrollbar(
                  thumbVisibility: true,
                  controller: _horizontal,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  notificationPredicate: (n) => n.depth == 1,
                  child: SingleChildScrollView(
                    controller: _horizontal,
                    primary: false,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: c.maxWidth),
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text(t.name)),
                          DataColumn(label: Text(t.email)),
                          DataColumn(label: Text(t.phone)),
                          DataColumn(label: Text(t.department)),
                          DataColumn(label: Text(t.menuJobTitles)),
                          DataColumn(label: Text(t.status)),
                          DataColumn(label: Text(t.hireDate)),
                          DataColumn(label: Text(t.created)),
                          DataColumn(label: Text(t.actions)),
                        ],
                        rows: widget.items.map((e) {
                          return DataRow(
                            cells: [
                              DataCell(Text(e.fullName)),
                              DataCell(Text(e.email)),
                              DataCell(Text(e.phone)),
                              DataCell(Text(e.departmentName ?? '-')),
                              DataCell(Text(e.jobTitleName ?? '-')),
                              DataCell(Text(e.status)),
                              DataCell(
                                Text(
                                  e.hireDate == null
                                      ? '-'
                                      : _formatDate(e.hireDate!),
                                ),
                              ),
                              DataCell(Text(_formatDate(e.createdAt))),
                              DataCell(
                                IconButton(
                                  tooltip: t.openProfile,
                                  icon: const Icon(Icons.badge_outlined),
                                  onPressed: widget.canOpenProfile
                                      ? () => context.go('/employees/${e.id}')
                                      : null,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
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
