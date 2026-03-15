import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/repos/hr_alerts_repo.dart';
import '../../domain/models/hr_alerts_data.dart';
import '../../domain/models/hr_alerts_summary.dart';
import '../widgets/hr_alerts/hr_alerts_filters.dart';
import '../widgets/hr_alerts/hr_alerts_settings_dialog.dart';
import '../widgets/hr_alerts/hr_alerts_summary_card.dart';
import '../widgets/hr_alerts/hr_alerts_table.dart';

class HrAlertsPage extends StatefulWidget {
  const HrAlertsPage({super.key, this.initialTypeFilter});

  final String? initialTypeFilter;

  @override
  State<HrAlertsPage> createState() => _HrAlertsPageState();
}

class _HrAlertsPageState extends State<HrAlertsPage> {
  final HrAlertsRepo _repo = HrAlertsRepo();
  late Future<HrAlertsData> _future;
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.initialTypeFilter;
    _future = _repo.load();
  }

  Future<void> _reload() async {
    setState(() => _future = _repo.load());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return FutureBuilder<HrAlertsData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _HrAlertsError(onRetry: _reload);
        }
        final data = snap.data!;
        final filteredItems = data.items.where((item) {
          if (_typeFilter == null) return true;
          if (_typeFilter == 'document') return item.type.startsWith('document:');
          return item.type == _typeFilter;
        }).toList();
        final summary = HrAlertsSummary.fromItems(filteredItems);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HrAlertsHeader(
                onRefresh: _reload,
                onSettings: () => _openSettings(data),
              ),
              const SizedBox(height: 12),
              HrAlertsFilters(
                typeFilter: _typeFilter,
                onChanged: (value) => setState(() => _typeFilter = value),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  HrAlertsSummaryCard(label: t.hrAlertsTotal, value: '${summary.total}', color: Theme.of(context).colorScheme.primary),
                  HrAlertsSummaryCard(label: t.hrBandExpired, value: '${summary.expired}', color: Colors.red.shade700),
                  HrAlertsSummaryCard(label: t.hrBandUrgent, value: '${summary.urgent}', color: Colors.orange.shade700),
                  HrAlertsSummaryCard(label: t.hrTypeDocument, value: '${summary.documents}', color: Colors.indigo.shade700),
                  HrAlertsSummaryCard(label: t.hrTypeContract, value: '${summary.contracts}', color: Colors.teal.shade700),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(child: HrAlertsTable(items: filteredItems)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSettings(HrAlertsData data) async {
    final t = AppLocalizations.of(context)!;
    final next = await showHrAlertsSettingsDialog(context, data.settings);
    if (next == null) return;
    try {
      await _repo.saveSettings(next);
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.hrAlertsSettingsSaved)));
    } catch (e, st) {
      debugPrint('HR_ALERT_SETTINGS_SAVE_ERROR: $e');
      debugPrint('HR_ALERT_SETTINGS_SAVE_STACK: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.saveFailed('$e'))));
    }
  }
}

class _HrAlertsHeader extends StatelessWidget {
  const _HrAlertsHeader({required this.onRefresh, required this.onSettings});

  final VoidCallback onRefresh;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(t.hrAlertsTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const Spacer(),
        OutlinedButton.icon(onPressed: onSettings, icon: const Icon(Icons.tune), label: Text(t.hrAlertsSettings)),
        const SizedBox(width: 8),
        OutlinedButton.icon(onPressed: onRefresh, icon: const Icon(Icons.refresh), label: Text(t.refresh)),
      ],
    );
  }
}

class _HrAlertsError extends StatelessWidget {
  const _HrAlertsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.hrAlertsLoadFailed, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(t.retry)),
        ],
      ),
    );
  }
}
