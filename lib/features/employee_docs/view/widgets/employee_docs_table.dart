import 'package:flutter/material.dart';
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
    final t = AppLocalizations.of(context)!;
    return BlocBuilder<EmployeeDocsCubit, EmployeeDocsState>(
      builder: (context, state) {
        final visibleEmployees = state.employees.where((employee) {
          final docs = state.docsMap[employee.id] ?? const <EmployeeDocument>[];
          final filteredDocs = docs.where((doc) => matchesExpiryFilter(doc, state.expiryStatus)).toList();
          return state.expiryStatus == null || filteredDocs.isNotEmpty;
        }).toList();

        if (visibleEmployees.isEmpty && !state.loading) {
          return _EmptyState(expiryStatus: state.expiryStatus);
        }

        return ListView.builder(
          itemCount: visibleEmployees.length,
          itemBuilder: (context, index) => EmployeeDocsEmployeeCard(employeeId: visibleEmployees[index].id),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.expiryStatus});

  final String? expiryStatus;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(expiryStatus == null ? t.noEmployeesFound : t.noDocumentsFound)),
      ),
    );
  }
}
