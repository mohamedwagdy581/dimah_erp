import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/leaves_cubit.dart';
import '../widgets/leaves_form_dialog.dart';

class LeavesCreateAction extends StatelessWidget {
  const LeavesCreateAction({
    super.key,
    required this.cubit,
    required this.employeeId,
  });

  final LeavesCubit cubit;
  final String? employeeId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ElevatedButton.icon(
      onPressed: () => _openCreateDialog(context),
      icon: const Icon(Icons.add),
      label: Text(t.addLeave),
    );
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<LeavesCubit>(),
        child: LeavesFormDialog(employeeId: employeeId),
      ),
    );
    if (ok == true && context.mounted) {
      cubit.load(resetPage: true);
    }
  }
}
