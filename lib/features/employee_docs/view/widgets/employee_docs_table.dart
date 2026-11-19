import 'package:material_ui/material_ui.dart';
import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/employee_document.dart';
import '../cubit/employee_docs_cubit.dart';
import '../cubit/employee_docs_state.dart';
import 'employee_docs_table/document_expiry_utils.dart';
import 'employee_docs_table/employee_docs_employee_card.dart';

class EmployeeDocsTable extends StatelessWidget {
  const EmployeeDocsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeDocsCubit, EmployeeDocsState>(
      builder: (context, state) {
        final visibleEmployees = state.employees.where((employee) {
          final docs = state.docsMap[employee.id] ?? const <EmployeeDocument>[];
          final filteredDocs = docs
              .where((doc) => matchesExpiryFilter(doc, state.expiryStatus))
              .toList();
          return state.expiryStatus == null || filteredDocs.isNotEmpty;
        }).toList();

        if (visibleEmployees.isEmpty && !state.loading) {
          final filtered =
              state.search.trim().isNotEmpty ||
              state.docType != null ||
              state.expiryStatus != null;
          return _EmptyState(
            expiryStatus: state.expiryStatus,
            filtered: filtered,
            onClear: filtered
                ? context.read<EmployeeDocsCubit>().resetFilters
                : null,
          );
        }

        return ListView.builder(
          itemCount: visibleEmployees.length,
          itemBuilder: (context, index) =>
              EmployeeDocsEmployeeCard(employeeId: visibleEmployees[index].id),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.expiryStatus,
    required this.filtered,
    this.onClear,
  });

  final String? expiryStatus;
  final bool filtered;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppEmptyState(
          title: filtered
              ? null
              : (expiryStatus == null
                    ? t.noEmployeesFound
                    : t.noDocumentsFound),
          filtered: filtered,
          onClear: onClear,
        ),
      ),
    );
  }
}
