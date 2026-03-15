import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/di/app_di.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../domain/models/employee_lookup.dart';
import '../../../cubit/employee_wizard_cubit.dart';

class JobManagerField extends StatelessWidget {
  const JobManagerField({super.key, required this.selectedManagerId});

  final String? selectedManagerId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return FutureBuilder<List<EmployeeLookup>>(
      future: AppDI.employeesRepo.fetchEmployeeLookup(limit: 200),
      builder: (context, snap) {
        final managers = snap.data ?? const <EmployeeLookup>[];
        return DropdownButtonFormField<String>(
          initialValue: selectedManagerId,
          decoration: InputDecoration(
            labelText: t.directManagerOptional,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<String>(value: '', child: Text(t.noDirectManager)),
            ...managers.map(
              (m) => DropdownMenuItem(value: m.id, child: Text(m.fullName)),
            ),
          ],
          onChanged: (v) => context.read<EmployeeWizardCubit>().setManagerId(
            (v == null || v.isEmpty) ? null : v,
          ),
        );
      },
    );
  }
}
