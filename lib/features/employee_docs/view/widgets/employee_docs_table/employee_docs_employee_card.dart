import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_document.dart';
import '../../cubit/employee_docs_cubit.dart';
import '../employee_docs_form_dialog.dart';
import 'count_chip.dart';
import 'document_card.dart';
import 'document_expiry_utils.dart';

class EmployeeDocsEmployeeCard extends StatelessWidget {
  const EmployeeDocsEmployeeCard({super.key, required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final state = context.watch<EmployeeDocsCubit>().state;
    final employee = state.employees.firstWhere((e) => e.id == employeeId);
    final isExpanded = state.expandedEmployeeIds.contains(employeeId);
    final docs = state.docsMap[employeeId] ?? const <EmployeeDocument>[];
    final filteredDocs = docs.where((doc) => matchesExpiryFilter(doc, state.expiryStatus)).toList();
    final counts = buildDocumentCounts(docs);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(employee.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  CountChip(label: '${docs.length} ${t.documents}', color: Theme.of(context).colorScheme.primary),
                  CountChip(label: '${counts.expired} ${t.expired}', color: Theme.of(context).colorScheme.error),
                  CountChip(label: '${counts.expiringSoon} ${t.expiringSoon}', color: Colors.orange),
                  CountChip(label: '${counts.valid} ${t.valid}', color: Colors.green),
                ],
              ),
            ),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => context.read<EmployeeDocsCubit>().toggleExpansion(employeeId),
          ),
          if (isExpanded) _ExpandedEmployeeDocs(employeeId: employeeId, docs: filteredDocs),
        ],
      ),
    );
  }
}

class _ExpandedEmployeeDocs extends StatelessWidget {
  const _ExpandedEmployeeDocs({required this.employeeId, required this.docs});

  final String employeeId;
  final List<EmployeeDocument> docs;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (docs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(t.noDocumentsFound, style: const TextStyle(color: Colors.grey)),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 185,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.64,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) => DocumentCard(doc: docs[index]),
            ),
          const Divider(),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _openAddDialog(context),
              icon: const Icon(Icons.upload_file),
              label: Text(t.uploadNewDocument),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddDialog(BuildContext context) async {
    final cubit = context.read<EmployeeDocsCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: EmployeeDocsFormDialog(initialEmployeeId: employeeId),
      ),
    );
    if (ok == true) {
      cubit.load(resetPage: true);
    }
  }
}
