import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../employees/domain/models/expiry_alert.dart';

class HrAlertsPage extends StatefulWidget {
  const HrAlertsPage({super.key, this.initialTypeFilter});

  final String? initialTypeFilter;

  @override
  State<HrAlertsPage> createState() => _HrAlertsPageState();
}

class _HrAlertsPageState extends State<HrAlertsPage> {
  late Future<_AlertsData> _future;
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.initialTypeFilter;
    _future = _load();
  }

  Future<_AlertsData> _load() async {
    final settings = await AppDI.employeesRepo.fetchExpiryAlertSettings();
    final items = await AppDI.employeesRepo.fetchExpiryAlerts();
    return _AlertsData(settings: settings, items: items);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return FutureBuilder<_AlertsData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.hrAlertsLoadFailed,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(snap.error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                  label: Text(t.retry),
                ),
              ],
            ),
          );
        }

        final data = snap.data!;
        final filteredItems = data.items.where((item) {
          if (_typeFilter == null) return true;
          if (_typeFilter == 'document') {
            return item.type.startsWith('document:');
          }
          return item.type == _typeFilter;
        }).toList();
        final summary = _AlertsSummary.fromItems(filteredItems);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    t.hrAlertsTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _openSettings(data.settings),
                    icon: const Icon(Icons.tune),
                    label: Text(t.hrAlertsSettings),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(t.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  DropdownButton<String?>(
                    value: _typeFilter,
                    onChanged: (value) {
                      setState(() => _typeFilter = value);
                    },
                    items: [
                      DropdownMenuItem(value: null, child: Text(t.allTypes)),
                      DropdownMenuItem(
                        value: 'contract',
                        child: Text(t.hrTypeContract),
                      ),
                      DropdownMenuItem(
                        value: 'residency',
                        child: Text(t.hrTypeResidency),
                      ),
                      DropdownMenuItem(
                        value: 'insurance',
                        child: Text(t.hrTypeInsurance),
                      ),
                      DropdownMenuItem(
                        value: 'document',
                        child: Text(t.hrTypeDocument),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(
                    label: t.hrAlertsTotal,
                    value: '${summary.total}',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  _SummaryCard(
                    label: t.hrBandExpired,
                    value: '${summary.expired}',
                    color: Colors.red.shade700,
                  ),
                  _SummaryCard(
                    label: t.hrBandUrgent,
                    value: '${summary.urgent}',
                    color: Colors.orange.shade700,
                  ),
                  _SummaryCard(
                    label: t.hrTypeDocument,
                    value: '${summary.documents}',
                    color: Colors.indigo.shade700,
                  ),
                  _SummaryCard(
                    label: t.hrTypeContract,
                    value: '${summary.contracts}',
                    color: Colors.teal.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _AlertsTable(items: filteredItems),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSettings(ExpiryAlertSettings current) async {
    final t = AppLocalizations.of(context)!;
    final contractCtrl = TextEditingController(
      text: current.contractAlertDays.toString(),
    );
    final residencyCtrl = TextEditingController(
      text: current.residencyAlertDays.toString(),
    );
    final insuranceCtrl = TextEditingController(
      text: current.insuranceAlertDays.toString(),
    );
    final documentsCtrl = TextEditingController(
      text: current.documentsAlertDays.toString(),
    );
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.hrAlertsSettingsTitle),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _daysField(
                  controller: contractCtrl,
                  label: t.hrAlertsContractDays,
                ),
                const SizedBox(height: 10),
                _daysField(
                  controller: residencyCtrl,
                  label: t.hrAlertsResidencyDays,
                ),
                const SizedBox(height: 10),
                _daysField(
                  controller: insuranceCtrl,
                  label: t.hrAlertsInsuranceDays,
                ),
                const SizedBox(height: 10),
                _daysField(
                  controller: documentsCtrl,
                  label: t.hrAlertsDocumentsDays,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(dialogContext, true);
            },
            child: Text(t.save),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await AppDI.employeesRepo.upsertExpiryAlertSettings(
        ExpiryAlertSettings(
          contractAlertDays: int.parse(contractCtrl.text.trim()),
          residencyAlertDays: int.parse(residencyCtrl.text.trim()),
          insuranceAlertDays: int.parse(insuranceCtrl.text.trim()),
          documentsAlertDays: int.parse(documentsCtrl.text.trim()),
        ),
      );
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.hrAlertsSettingsSaved)));
    } catch (e, st) {
      debugPrint('HR_ALERT_SETTINGS_SAVE_ERROR: $e');
      debugPrint('HR_ALERT_SETTINGS_SAVE_STACK: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.saveFailed('$e'))));
    }
  }

  Widget _daysField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        final n = int.tryParse((v ?? '').trim());
        if (n == null || n <= 0 || n > 365) {
          return AppLocalizations.of(context)!.validationRange1To365;
        }
        return null;
      },
    );
  }
}

class _AlertsTable extends StatelessWidget {
  const _AlertsTable({required this.items});

  final List<ExpiryAlertItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        child: Center(child: Text(AppLocalizations.of(context)!.hrAlertsNoRows)),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: [
              DataColumn(label: Text(AppLocalizations.of(context)!.hrAlertsColEmployee)),
              DataColumn(label: Text(AppLocalizations.of(context)!.hrAlertsColType)),
              DataColumn(label: Text(AppLocalizations.of(context)!.hrAlertsColExpiryDate)),
              DataColumn(label: Text(AppLocalizations.of(context)!.hrAlertsColDaysLeft)),
              DataColumn(label: Text(AppLocalizations.of(context)!.hrAlertsColStatus)),
              DataColumn(label: Text(AppLocalizations.of(context)!.actions)),
            ],
            rows: items.map((e) {
              final band = _band(context, e.daysLeft);
              return DataRow(
                color: WidgetStatePropertyAll(band.bg),
                cells: [
                  DataCell(Text(e.employeeName)),
                  DataCell(Text(_labelForType(context, e.type))),
                  DataCell(Text(_fmtDate(e.expiryDate))),
                  DataCell(
                    Text(
                      '${e.daysLeft}',
                      style: TextStyle(
                        color: band.fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DataCell(
                    Chip(
                      label: Text(band.label),
                      backgroundColor: band.bg,
                      side: BorderSide(color: band.fg.withValues(alpha: 0.4)),
                    ),
                  ),
                  DataCell(
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            context.push(
                              AppRoutes.employeeProfile.replaceFirst(':id', e.employeeId),
                            );
                          },
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: Text(AppLocalizations.of(context)!.openProfile),
                        ),
                        if (e.type.startsWith('document:') &&
                            (e.fileUrl ?? '').trim().isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () => _openDocument(context, e.fileUrl!),
                            icon: const Icon(Icons.description_outlined, size: 16),
                            label: Text(AppLocalizations.of(context)!.openDocument),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _openDocument(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.invalidFileUrl)));
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.unableOpenFile)));
    }
  }

  _Band _band(BuildContext context, int daysLeft) {
    final t = AppLocalizations.of(context)!;
    if (daysLeft < 0) {
      return _Band(
        label: t.hrBandExpired,
        fg: Colors.red.shade800,
        bg: Colors.red.withValues(alpha: 0.18),
      );
    }
    if (daysLeft < 30) {
      return _Band(
        label: t.hrBandUrgent,
        fg: Colors.red.shade700,
        bg: Colors.red.withValues(alpha: 0.12),
      );
    }
    if (daysLeft < 90) {
      return _Band(
        label: t.hrBandWarning,
        fg: Colors.amber.shade800,
        bg: Colors.amber.withValues(alpha: 0.20),
      );
    }
    if (daysLeft <= 120) {
      return _Band(
        label: t.hrBandUpcoming,
        fg: Colors.yellow.shade900,
        bg: Colors.yellow.withValues(alpha: 0.18),
      );
    }
    return _Band(
      label: t.hrBandSafe,
      fg: Colors.green.shade800,
      bg: Colors.green.withValues(alpha: 0.14),
    );
  }

  String _labelForType(BuildContext context, String type) {
    final t = AppLocalizations.of(context)!;
    if (type == 'contract') return t.hrTypeContract;
    if (type == 'residency') return t.hrTypeResidency;
    if (type == 'insurance') return t.hrTypeInsurance;
    if (type.startsWith('document:')) {
      final docType = type.substring('document:'.length);
      return '${t.hrTypeDocument}: ${_documentLabel(t, docType)}';
    }
    return type;
  }

  String _documentLabel(AppLocalizations t, String docType) {
    switch (docType) {
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

  String _fmtDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}

class _Band {
  const _Band({required this.label, required this.fg, required this.bg});

  final String label;
  final Color fg;
  final Color bg;
}

class _AlertsData {
  const _AlertsData({required this.settings, required this.items});

  final ExpiryAlertSettings settings;
  final List<ExpiryAlertItem> items;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AlertsSummary {
  const _AlertsSummary({
    required this.total,
    required this.expired,
    required this.urgent,
    required this.documents,
    required this.contracts,
  });

  final int total;
  final int expired;
  final int urgent;
  final int documents;
  final int contracts;

  factory _AlertsSummary.fromItems(List<ExpiryAlertItem> items) {
    var expired = 0;
    var urgent = 0;
    var documents = 0;
    var contracts = 0;
    for (final item in items) {
      if (item.daysLeft < 0) expired++;
      if (item.daysLeft >= 0 && item.daysLeft < 30) urgent++;
      if (item.type.startsWith('document:')) documents++;
      if (item.type == 'contract') contracts++;
    }
    return _AlertsSummary(
      total: items.length,
      expired: expired,
      urgent: urgent,
      documents: documents,
      contracts: contracts,
    );
  }
}
