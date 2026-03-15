import 'package:flutter/material.dart';

import '../../../../core/di/app_di.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../employees/domain/models/employee_lookup.dart';
import '../../domain/models/department.dart';
import 'department_form_dialog_actions.dart';
import 'department_form_dialog_manager_field.dart';

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
              DepartmentManagerField(
                managersFuture: _managersFuture,
                managerId: _managerId,
                onChanged: (value) => setState(() => _managerId = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        DepartmentFormDialogActions(
          formKey: _formKey,
          nameController: _name,
          codeController: _code,
          descriptionController: _desc,
          managerId: _managerId,
          edit: widget.edit,
        ),
      ],
    );
  }
}
