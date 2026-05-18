import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/employee_settlement_summary.dart';
import '../utils/employee_profile_utils.dart';

class SettlementsTable extends StatelessWidget {
  const SettlementsTable({
    super.key,
    required this.items,
  });

  final List<EmployeeSettlementSummary> items;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(t.noSettlementsFound)),
        ),
      );
    }

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: 24,
                horizontalMargin: 16,
                columns: [
                  DataColumn(label: Text(t.selectPhoto)),
                  DataColumn(label: Text(t.code)),
                  DataColumn(label: Text(t.fullName)),
                  DataColumn(label: Text(t.menuJobTitles)),
                  DataColumn(label: Text(t.status)),
                  DataColumn(label: Text(t.latestSettlementDate)),
                  DataColumn(label: Text(t.settlementCount)),
                  DataColumn(label: Text(t.netAmount)),
                  DataColumn(label: Text(t.actions)),
                ],
                rows: items.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(
                        CircleAvatar(
                          radius: 18,
                          backgroundImage:
                              resolveEmployeePhotoProvider(item.photoUrl),
                          child: (item.photoUrl ?? '').trim().isEmpty
                              ? const Icon(Icons.person, size: 18)
                              : null,
                        ),
                      ),
                      DataCell(Text(item.employeeNumber ?? '-')),
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: Text(
                            item.fullName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(item.jobTitleName ?? '-')),
                      DataCell(
                        Text(item.status == 'active' ? t.active : t.inactive),
                      ),
                      DataCell(Text(formatEmployeeDate(item.latestSettlementDate))),
                      DataCell(Text('${item.settlementsCount}')),
                      DataCell(
                        Text(
                          item.latestNetAmount == null
                              ? '-'
                              : item.latestNetAmount!.toStringAsFixed(2),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          tooltip: t.openProfile,
                          onPressed: () =>
                              context.go('/employees/${item.employeeId}'),
                          icon: const Icon(Icons.badge_outlined),
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
