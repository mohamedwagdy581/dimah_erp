import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../employees/domain/models/employee_lookup.dart';

class DepartmentManagerField extends StatelessWidget {
  const DepartmentManagerField({
    super.key,
    required this.managersFuture,
    required this.managerId,
    required this.onChanged,
  });

  final Future<List<EmployeeLookup>> managersFuture;
  final String? managerId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return FutureBuilder<List<EmployeeLookup>>(
      future: managersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text(
            '${t.unableToLoadManagers}: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }
        final rawManagers = snapshot.data ?? const <EmployeeLookup>[];
        final seen = <String>{};
        final managers = rawManagers.where((manager) {
          if (seen.contains(manager.id)) {
            return false;
          }
          seen.add(manager.id);
          return true;
        }).toList();
        final currentValue =
            managers.any((manager) => manager.id == managerId) ? managerId : '';
        return DropdownButtonFormField<String>(
          initialValue: currentValue,
          decoration: InputDecoration(labelText: t.departmentManager),
          items: [
            DropdownMenuItem(value: '', child: Text(t.noManager)),
            ...managers.map(
              (manager) => DropdownMenuItem(
                value: manager.id,
                child: Text(manager.fullName),
              ),
            ),
          ],
          onChanged: (value) =>
              onChanged((value ?? '').trim().isEmpty ? null : value),
        );
      },
    );
  }
}
