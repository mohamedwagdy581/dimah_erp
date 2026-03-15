import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/employee_docs_cubit.dart';
import '../widgets/employee_docs_form_dialog.dart';

class EmployeeDocsCreateAction extends StatelessWidget {
  const EmployeeDocsCreateAction({super.key, required this.cubit});

  final EmployeeDocsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ElevatedButton.icon(
      onPressed: () => _openCreateDialog(context),
      icon: const Icon(Icons.add),
      label: Text(t.addDocument),
    );
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<EmployeeDocsCubit>(),
        child: const EmployeeDocsFormDialog(),
      ),
    );
    if (ok == true && context.mounted) {
      cubit.load(resetPage: true);
    }
  }
}
