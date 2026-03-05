import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/app_di.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../employees/domain/models/employee_lookup.dart';
import '../../domain/models/department.dart';
import '../cubit/departments_cubit.dart';

class DepartmentFormDialog extends StatefulWidget {
  const DepartmentFormDialog({super.key, this.edit});

  final Department? edit;

  @override
  State<DepartmentFormDialog> createState() => _DepartmentFormDialogState();
}

class _DepartmentFormDialogState extends State<DepartmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _desc;
  String? _managerId;
  late Future<List<EmployeeLookup>> _managersFuture;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.edit?.name ?? '');
    _code = TextEditingController(text: widget.edit?.code ?? '');
    _desc = TextEditingController(text: widget.edit?.description ?? '');
    _managerId = widget.edit?.managerId;
    _managersFuture = AppDI.employeesRepo.fetchEmployeeLookup(limit: 300);
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isEdit = widget.edit != null;

    return AlertDialog(
      title: Text(isEdit ? t.editDepartment : t.addDepartment),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: t.name),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? t.requiredField : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _code,
                decoration: InputDecoration(labelText: t.codeOptional),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _desc,
                decoration: InputDecoration(
                  labelText: t.descriptionOptional,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<EmployeeLookup>>(
                future: _managersFuture,
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
                  final managers = rawManagers.where((m) {
                    if (seen.contains(m.id)) return false;
                    seen.add(m.id);
                    return true;
                  }).toList();
                  final currentValue = managers.any((m) => m.id == _managerId)
                      ? _managerId
                      : '';
                  return DropdownButtonFormField<String>(
                    initialValue: currentValue,
                    decoration: InputDecoration(
                      labelText: t.departmentManager,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(t.noManager),
                      ),
                      ...managers.map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.fullName),
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _managerId = (v ?? '').trim().isEmpty ? null : v),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final cubit = context.read<DepartmentsCubit>();

            if (isEdit) {
              await cubit.update(
                id: widget.edit!.id,
                name: _name.text,
                code: _code.text,
                description: _desc.text,
                managerId: _managerId,
                isActive: widget.edit!.isActive,
              );
            } else {
              await cubit.create(
                name: _name.text,
                code: _code.text,
                description: _desc.text,
                managerId: _managerId,
              );
            }
            if (context.mounted) Navigator.pop(context, true);
          },
          child: Text(isEdit ? t.save : t.create),
        ),
      ],
    );
  }
}
