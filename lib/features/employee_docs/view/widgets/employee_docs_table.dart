import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/employee_document.dart';

class EmployeeDocsTable extends StatelessWidget {
  const EmployeeDocsTable({super.key, required this.items});

  final List<EmployeeDocument> items;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(t.noDocumentsFound)),
        ),
      );
    }

    return Card(
      child: LayoutBuilder(
        builder: (context, c) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: c.maxWidth),
              child: DataTable(
                columns: [
                  DataColumn(label: Text(t.employee)),
                  DataColumn(label: Text(t.type)),
                  DataColumn(label: Text(t.issued)),
                  DataColumn(label: Text(t.expires)),
                  DataColumn(label: Text(t.file)),
                ],
                rows: items.map((d) {
                  return DataRow(
                    cells: [
                      DataCell(Text(d.employeeName)),
                      DataCell(Text(d.docType)),
                      DataCell(Text(_formatDate(d.issuedAt))),
                      DataCell(Text(_formatDate(d.expiresAt))),
                      DataCell(
                        d.fileUrl.isEmpty
                            ? const Text('-')
                            : TextButton(
                                onPressed: () => _openFile(context, d.fileUrl),
                                child: Text(t.open),
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openFile(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.invalidFileUrl)));
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.unableOpenFile)),
      );
    }
  }
}
