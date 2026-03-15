import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/attendance_cubit.dart';
import '../widgets/attendance_form_dialog.dart';
import '../widgets/attendance_import_dialog.dart';

class ImportAttendanceButton extends StatelessWidget {
  const ImportAttendanceButton({super.key, required this.cubit});

  final AttendanceCubit cubit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: () => _openImportDialog(context),
      icon: const Icon(Icons.upload_file_outlined),
      label: Text(t.importCsv),
    );
  }

  Future<void> _openImportDialog(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AttendanceCubit>(),
        child: const AttendanceImportDialog(),
      ),
    );
    if (ok == true && context.mounted) {
      cubit.load(resetPage: true);
    }
  }
}

class AddAttendanceButton extends StatelessWidget {
  const AddAttendanceButton({super.key, required this.cubit});

  final AttendanceCubit cubit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ElevatedButton.icon(
      onPressed: () => _openCreateDialog(context),
      icon: const Icon(Icons.add),
      label: Text(t.addAttendance),
    );
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AttendanceCubit>(),
        child: const AttendanceFormDialog(),
      ),
    );
    if (ok == true && context.mounted) {
      cubit.load(resetPage: true);
    }
  }
}
