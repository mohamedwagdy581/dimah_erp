import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/department.dart';
import '../cubit/departments_cubit.dart';
import '../widgets/department_form_dialog.dart';

Future<void> openDepartmentEditDialog(
  BuildContext context,
  Department department,
) async {
  final cubit = context.read<DepartmentsCubit>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: DepartmentFormDialog(edit: department),
    ),
  );
  if (ok == true && context.mounted) {
    cubit.load();
  }
}
