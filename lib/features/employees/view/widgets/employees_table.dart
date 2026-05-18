import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/employee.dart';
import '../utils/employee_profile_utils.dart';

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
  static const double _minTableWidth = 920;

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
    final isCompact = MediaQuery.sizeOf(context).width < _minTableWidth;

    if (widget.items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(t.noEmployeesFound)),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          if (isCompact)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'Scroll horizontally to reach all columns and actions.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
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
                        notificationPredicate: (notification) =>
                            notification.depth == 1,
                        child: SingleChildScrollView(
                          controller: _horizontal,
                          primary: false,
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth > _minTableWidth
                                  ? constraints.maxWidth
                                  : _minTableWidth,
                            ),
                            child: DataTable(
                              columnSpacing: 24,
                              horizontalMargin: 16,
                              columns: [
                                DataColumn(label: Text(t.selectPhoto)),
                                DataColumn(label: Text(t.code)),
                                DataColumn(label: Text(t.fullName)),
                                DataColumn(label: Text(t.menuJobTitles)),
                                DataColumn(label: Text(t.status)),
                                DataColumn(label: Text(t.hireDate)),
                                DataColumn(label: Text(t.actions)),
                              ],
                              rows: widget.items.map((employee) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      _EmployeePhotoCell(
                                        photoUrl: employee.photoUrl,
                                      ),
                                    ),
                                    DataCell(
                                      Text(employee.employeeNumber ?? '-'),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 180,
                                        child: Text(
                                          employee.fullName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 160,
                                        child: Text(
                                          employee.jobTitleName ?? '-',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(_employeeStatusLabel(employee.status, t)),
                                    ),
                                    DataCell(
                                      Text(formatEmployeeDate(employee.hireDate)),
                                    ),
                                    DataCell(
                                      IconButton(
                                        tooltip: t.openProfile,
                                        icon: const Icon(Icons.badge_outlined),
                                        onPressed: widget.canOpenProfile
                                            ? () => context.go(
                                                '/employees/${employee.id}',
                                              )
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
          ),
        ],
      ),
    );
  }

  String _employeeStatusLabel(String status, AppLocalizations t) {
    switch (status.toLowerCase()) {
      case 'active':
        return t.active;
      case 'inactive':
        return t.inactive;
      default:
        return status;
    }
  }
}

class _EmployeePhotoCell extends StatelessWidget {
  const _EmployeePhotoCell({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundImage: resolveEmployeePhotoProvider(photoUrl),
      child: (photoUrl ?? '').trim().isEmpty
          ? const Icon(Icons.person, size: 18)
          : null,
    );
  }
}
