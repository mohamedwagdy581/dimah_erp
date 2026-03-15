import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/department.dart';
import '../cubit/departments_cubit.dart';

class DepartmentFormDialogActions extends StatelessWidget {
  const DepartmentFormDialogActions({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.codeController,
    required this.descriptionController,
    required this.managerId,
    required this.edit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController descriptionController;
  final String? managerId;
  final Department? edit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isEdit = edit != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _submit(context),
          child: Text(isEdit ? t.save : t.create),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    final cubit = context.read<DepartmentsCubit>();
    if (edit != null) {
      await cubit.update(
        id: edit!.id,
        name: nameController.text,
        code: codeController.text,
        description: descriptionController.text,
        managerId: managerId,
        isActive: edit!.isActive,
      );
    } else {
      await cubit.create(
        name: nameController.text,
        code: codeController.text,
        description: descriptionController.text,
        managerId: managerId,
      );
    }
    if (context.mounted) {
      Navigator.pop(context, true);
    }
  }
}
