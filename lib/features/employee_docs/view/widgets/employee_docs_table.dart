import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/safe_file_picker.dart';
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
        final visibleEmployees = state.employees.where((employee) {
          final docs = state.docsMap[employee.id] ?? const <EmployeeDocument>[];
          final filteredDocs = docs
              .where((doc) => _matchesExpiryFilter(doc, state.expiryStatus))
              .toList();
          return state.expiryStatus == null || filteredDocs.isNotEmpty;
        }).toList();

        if (visibleEmployees.isEmpty && !state.loading) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  state.expiryStatus == null
                      ? t.noEmployeesFound
                      : t.noDocumentsFound,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: visibleEmployees.length,
          itemBuilder: (context, index) {
            final employee = visibleEmployees[index];
            final isExpanded = state.expandedEmployeeIds.contains(employee.id);
            final docs = state.docsMap[employee.id] ?? const <EmployeeDocument>[];
            final filteredDocs = docs
                .where((doc) => _matchesExpiryFilter(doc, state.expiryStatus))
                .toList();
            final counts = _buildCounts(docs);

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
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CountChip(
                            label: '${docs.length} ${t.documents}',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          _CountChip(
                            label: '${counts.expired} ${t.expired}',
                            color: Theme.of(context).colorScheme.error,
                          ),
                          _CountChip(
                            label:
                                '${counts.expiringSoon} ${t.expiringSoon}',
                            color: Colors.orange,
                          ),
                          _CountChip(
                            label: '${counts.valid} ${t.valid}',
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (filteredDocs.isEmpty)
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
                                maxCrossAxisExtent: 185,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.64,
                              ),
                              itemCount: filteredDocs.length,
                              itemBuilder: (context, dIndex) {
                                final doc = filteredDocs[dIndex];
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

  ({int expired, int expiringSoon, int valid}) _buildCounts(
    List<EmployeeDocument> docs,
  ) {
    var expired = 0;
    var expiringSoon = 0;
    var valid = 0;
    for (final doc in docs) {
      switch (_expiryStatus(doc.expiresAt)) {
        case _ExpiryStatus.expired:
          expired++;
        case _ExpiryStatus.expiringSoon:
          expiringSoon++;
        case _ExpiryStatus.valid:
          valid++;
        case _ExpiryStatus.noExpiry:
          break;
      }
    }
    return (expired: expired, expiringSoon: expiringSoon, valid: valid);
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
      cubit.load(resetPage: true);
    }
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.doc, required this.t});

  final EmployeeDocument doc;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionStyle = OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const Size(0, 30),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    );
    final iconData = _iconForDocType(doc.docType);
    final iconColor = _iconColorForDocType(context, doc.docType);
    final status = _expiryStatus(doc.expiresAt);
    final statusColor = _statusColor(theme, status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _previewDocument(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 96,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel(t, status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<_DocAction>(
                          tooltip: t.actions,
                          onSelected: (value) async {
                            switch (value) {
                              case _DocAction.preview:
                                await _previewDocument(context);
                                break;
                              case _DocAction.download:
                                await _downloadFile(context);
                                break;
                              case _DocAction.edit:
                                await _editDocument(context);
                                break;
                              case _DocAction.delete:
                                await _deleteDocument(context);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<_DocAction>(
                              value: _DocAction.preview,
                              child: Text(t.preview),
                            ),
                            PopupMenuItem<_DocAction>(
                              value: _DocAction.download,
                              child: Text(t.download),
                            ),
                            PopupMenuItem<_DocAction>(
                              value: _DocAction.edit,
                              child: Text(t.edit),
                            ),
                            PopupMenuItem<_DocAction>(
                              value: _DocAction.delete,
                              child: Text(t.delete),
                            ),
                          ],
                          child: Container(
                            height: 28,
                            width: 28,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.more_horiz,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(iconData, size: 40, color: iconColor),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _docTypeLabel(t, doc.docType),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fileTypeLabel(t, doc.fileUrl),
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (doc.expiresAt != null)
                    Text(
                      '${t.expires}: ${_formatDate(doc.expiresAt)}',
                      style: TextStyle(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: actionStyle,
                        onPressed: () => _previewDocument(context),
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: Text(t.open),
                      ),
                    ],
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
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.invalidFileUrl)));
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _previewDocument(BuildContext context) async {
    if (!_isImageFile(doc.fileUrl)) {
      await _openFile(context, doc.fileUrl);
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 720,
          height: 720,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _docTypeLabel(t, doc.docType),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      doc.fileUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(t.unableOpenFile),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editDocument(BuildContext context) async {
    final cubit = context.read<EmployeeDocsCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: EmployeeDocsFormDialog(initialDocument: doc),
      ),
    );
    if (ok == true && context.mounted) {
      cubit.load();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.documentUpdated)));
    }
  }

  Future<void> _deleteDocument(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.deleteDocument),
        content: Text(t.deleteDocumentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<EmployeeDocsCubit>().delete(
        id: doc.id,
        employeeId: doc.employeeId,
        fileUrl: doc.fileUrl,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.documentDeleted)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.saveFailed(e.toString()))));
    }
  }

  Future<void> _downloadFile(BuildContext context) async {
    try {
      final path = _storagePathFromPublicUrl(doc.fileUrl);
      if (path == null) {
        throw Exception(t.invalidFileUrl);
      }
      final suggestedName = Uri.tryParse(doc.fileUrl)?.pathSegments.last ??
          '${doc.docType}.bin';
      final ext = suggestedName.contains('.')
          ? suggestedName.split('.').last.toLowerCase()
          : '';
      final saveLocation = await SafeFilePicker.saveLocation(
        context: context,
        suggestedName: suggestedName,
        acceptedTypeGroups: [
          XTypeGroup(
            label: t.file,
            extensions: ext.isEmpty ? null : [ext],
          ),
        ],
      );
      if (saveLocation == null || saveLocation.path.isEmpty) return;

      final bytes = await Supabase.instance.client.storage
          .from('employee_docs')
          .download(path);
      await File(saveLocation.path).writeAsBytes(bytes, flush: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.fileSavedTo(saveLocation.path))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.fileDownloadFailed(e.toString()))));
    }
  }
}

String _docTypeLabel(AppLocalizations t, String type) {
  switch (type) {
    case 'id_card':
      return t.idCard;
    case 'passport':
      return t.passport;
    case 'cv':
      return 'CV';
    case 'graduation_cert':
      return t.graduationCert;
    case 'national_address':
      return t.nationalAddress;
    case 'bank_iban_certificate':
      return t.bankIbanCertificate;
    case 'salary_certificate':
      return t.salaryCertificate;
    case 'salary_definition':
      return t.salaryDefinition;
    case 'contract':
      return t.contract;
    case 'residency':
      return t.residencyDocument;
    case 'driving_license':
      return t.drivingLicense;
    case 'offer_letter':
      return t.offerLetter;
    case 'medical_insurance':
      return t.medicalInsurance;
    case 'medical_report':
      return t.medicalReport;
    default:
      return t.other;
  }
}

IconData _iconForDocType(String type) {
  switch (type) {
    case 'id_card':
    case 'passport':
    case 'residency':
    case 'national_address':
      return Icons.badge_outlined;
    case 'cv':
    case 'offer_letter':
    case 'salary_certificate':
    case 'salary_definition':
    case 'graduation_cert':
      return Icons.description_outlined;
    case 'bank_iban_certificate':
      return Icons.account_balance_outlined;
    case 'contract':
      return Icons.assignment_outlined;
    case 'driving_license':
      return Icons.directions_car_outlined;
    case 'medical_insurance':
    case 'medical_report':
      return Icons.health_and_safety_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

Color _iconColorForDocType(BuildContext context, String type) {
  final theme = Theme.of(context);
  switch (type) {
    case 'id_card':
    case 'passport':
    case 'residency':
    case 'national_address':
      return theme.colorScheme.primary;
    case 'bank_iban_certificate':
    case 'salary_certificate':
    case 'salary_definition':
      return Colors.teal;
    case 'medical_insurance':
    case 'medical_report':
      return Colors.redAccent;
    case 'contract':
    case 'offer_letter':
      return Colors.deepPurpleAccent;
    case 'graduation_cert':
    case 'cv':
      return Colors.indigo;
    default:
      return theme.colorScheme.secondary;
  }
}

_ExpiryStatus _expiryStatus(DateTime? expiresAt) {
  if (expiresAt == null) return _ExpiryStatus.noExpiry;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final expiry = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
  final days = expiry.difference(today).inDays;
  if (days < 0) return _ExpiryStatus.expired;
  if (days <= 30) return _ExpiryStatus.expiringSoon;
  return _ExpiryStatus.valid;
}

bool _matchesExpiryFilter(EmployeeDocument doc, String? expiryFilter) {
  if (expiryFilter == null) return true;
  final status = _expiryStatus(doc.expiresAt);
  switch (expiryFilter) {
    case 'expired':
      return status == _ExpiryStatus.expired;
    case 'expiring_soon':
      return status == _ExpiryStatus.expiringSoon;
    case 'valid':
      return status == _ExpiryStatus.valid;
    case 'no_expiry':
      return status == _ExpiryStatus.noExpiry;
    default:
      return true;
  }
}

String _statusLabel(AppLocalizations t, _ExpiryStatus status) {
  switch (status) {
    case _ExpiryStatus.expired:
      return t.expired;
    case _ExpiryStatus.expiringSoon:
      return t.expiringSoon;
    case _ExpiryStatus.valid:
      return t.valid;
    case _ExpiryStatus.noExpiry:
      return t.noExpiry;
  }
}

Color _statusColor(ThemeData theme, _ExpiryStatus status) {
  switch (status) {
    case _ExpiryStatus.expired:
      return theme.colorScheme.error;
    case _ExpiryStatus.expiringSoon:
      return Colors.orange;
    case _ExpiryStatus.valid:
      return Colors.green;
    case _ExpiryStatus.noExpiry:
      return theme.colorScheme.primary;
  }
}

String _fileTypeLabel(AppLocalizations t, String fileUrl) {
  final lastSegment = Uri.tryParse(fileUrl)?.pathSegments.last;
  final rawExt = lastSegment?.split('.').last;
  final ext = rawExt?.toUpperCase();
  if (ext == null || ext.isEmpty || ext == (lastSegment?.toUpperCase())) {
    return t.documentFile;
  }
  return '$ext ${t.file}';
}

enum _ExpiryStatus { expired, expiringSoon, valid, noExpiry }

enum _DocAction { preview, download, edit, delete }

String? _storagePathFromPublicUrl(String fileUrl) {
  final uri = Uri.tryParse(fileUrl);
  if (uri == null) return null;
  final bucketIndex = uri.pathSegments.indexOf('employee_docs');
  if (bucketIndex == -1 || bucketIndex + 1 >= uri.pathSegments.length) {
    return null;
  }
  return uri.pathSegments.sublist(bucketIndex + 1).join('/');
}

bool _isImageFile(String fileUrl) {
  final lower = fileUrl.toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp');
}
