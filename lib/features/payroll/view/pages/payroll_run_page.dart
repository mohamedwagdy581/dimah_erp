import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/utils/safe_file_picker.dart';
import '../../domain/models/payroll_item.dart';
import '../cubit/payroll_run_cubit.dart';
import '../cubit/payroll_run_state.dart';
import '../widgets/payroll_run_items_table.dart';

class PayrollRunPage extends StatelessWidget {
  const PayrollRunPage({super.key, required this.runId});

  final String runId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PayrollRunCubit(AppDI.payrollRepo)..load(runId),
      child: _PayrollRunBody(runId: runId),
    );
  }
}

class _PayrollRunBody extends StatelessWidget {
  const _PayrollRunBody({required this.runId});

  final String runId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return BlocBuilder<PayrollRunCubit, PayrollRunState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    t.payrollRunItems,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _finalizeRun(context, runId),
                    icon: const Icon(Icons.lock),
                    label: Text(t.finalize),
                  ),
                  ElevatedButton.icon(
                    onPressed: state.items.isEmpty
                        ? null
                        : () => _exportCsvFile(context, state.items),
                    icon: const Icon(Icons.download),
                    label: Text(t.exportCsv),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 12),

              Expanded(child: PayrollRunItemsTable(items: state.items)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _finalizeRun(BuildContext context, String runId) async {
    final t = AppLocalizations.of(context)!;
    try {
      await AppDI.payrollRepo.finalizeRun(runId: runId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.payrollRunFinalized)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _exportCsvFile(
    BuildContext context,
    List<PayrollItem> items,
  ) async {
    final t = AppLocalizations.of(context)!;
    final buffer = StringBuffer();
    buffer.writeln('${t.employee},${t.basic},${t.housing},${t.transport},${t.other},${t.total}');
    for (final r in items) {
      buffer.writeln(
        '${_csv(r.employeeName)},${r.basicSalary},${r.housingAllowance},'
        '${r.transportAllowance},${r.otherAllowance},${r.total}',
      );
    }
    final totalBasic = items.fold<num>(0, (sum, r) => sum + r.basicSalary);
    final totalHousing = items.fold<num>(0, (sum, r) => sum + r.housingAllowance);
    final totalTransport = items.fold<num>(0, (sum, r) => sum + r.transportAllowance);
    final totalOther = items.fold<num>(0, (sum, r) => sum + r.otherAllowance);
    final totalAll = items.fold<num>(0, (sum, r) => sum + r.total);
    buffer.writeln(
      '${_csv('TOTAL')},$totalBasic,$totalHousing,$totalTransport,$totalOther,$totalAll',
    );

    final fileName = 'payroll_${DateTime.now().millisecondsSinceEpoch}.csv';
    try {
      final saveLocation = await SafeFilePicker.saveLocation(
        context: context,
        suggestedName: fileName,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'CSV', extensions: ['csv']),
        ],
      );
      if (saveLocation == null) return;

      final data = Uint8List.fromList(buffer.toString().codeUnits);
      final file = XFile.fromData(data, name: fileName, mimeType: 'text/csv');
      await file.saveTo(saveLocation.path);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.csvSavedTo(saveLocation.path))),
      );
    } on PlatformException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.exportFailed(e.message ?? e.code))),
      );
    }
  }

  String _csv(String v) {
    final escaped = v.replaceAll('"', '""');
    return '"$escaped"';
  }
}
