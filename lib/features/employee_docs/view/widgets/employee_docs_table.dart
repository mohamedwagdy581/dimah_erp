import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/employee_document.dart';
import '../cubit/employee_docs_cubit.dart';
import '../cubit/employee_docs_state.dart';
import 'employee_docs_form_dialog.dart';

class EmployeeDocsTable extends StatelessWidget {
  const EmployeeDocsTable({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return BlocBuilder<EmployeeDocsCubit, EmployeeDocsState>(
      builder: (context, state) {
        if (state.employees.isEmpty && !state.loading) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(t.noEmployeesFound)),
            ),
          );
        }

        return ListView.builder(
          itemCount: state.employees.length,
          itemBuilder: (context, index) {
            final employee = state.employees[index];
            final isExpanded = state.expandedEmployeeIds.contains(employee.id);
            final docs = state.docsMap[employee.id] ?? [];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(
                      employee.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${docs.length} ${t.documents}'),
                    trailing: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onTap: () =>
                        context.read<EmployeeDocsCubit>().toggleExpansion(
                          employee.id,
                        ),
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (docs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                t.noDocumentsFound,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 200,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 0.8,
                                  ),
                              itemCount: docs.length,
                              itemBuilder: (context, dIndex) {
                                final doc = docs[dIndex];
                                return _DocumentCard(doc: doc, t: t);
                              },
                            ),
                          const Divider(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () => _openAddDialog(context, employee.id),
                              icon: const Icon(Icons.upload_file),
                              label: Text(t.uploadNewDocument),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openAddDialog(BuildContext context, String employeeId) async {
    final cubit = context.read<EmployeeDocsCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: EmployeeDocsFormDialog(initialEmployeeId: employeeId),
      ),
    );
    if (ok == true) {
      // Logic handled in cubit.create
    }
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.doc, required this.t});
  final EmployeeDocument doc;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final isPdf = doc.fileUrl.toLowerCase().endsWith('.pdf');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _openFile(context, doc.fileUrl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.image,
                  size: 48,
                  color: isPdf ? Colors.red : Colors.blue,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.docType.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (doc.expiresAt != null)
                    Text(
                      '${t.expires}: ${_formatDate(doc.expiresAt)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openFile(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
