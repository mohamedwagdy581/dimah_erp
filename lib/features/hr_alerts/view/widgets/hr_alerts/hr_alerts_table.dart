import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/routing/app_routes.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../employees/domain/models/expiry_alert.dart';
import 'hr_alerts_table_utils.dart';

class HrAlertsTable extends StatelessWidget {
  const HrAlertsTable({super.key, required this.items});

  final List<ExpiryAlertItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(child: Center(child: Text(AppLocalizations.of(context)!.hrAlertsNoRows)));
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
            rows: items.map((item) => _buildRow(context, item)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, ExpiryAlertItem item) {
    final band = alertBand(context, item.daysLeft);
    return DataRow(
      color: WidgetStatePropertyAll(band.bg),
      cells: [
        DataCell(Text(item.employeeName)),
        DataCell(Text(alertTypeLabel(context, item.type))),
        DataCell(Text(formatAlertDate(item.expiryDate))),
        DataCell(Text('${item.daysLeft}', style: TextStyle(color: band.fg, fontWeight: FontWeight.w700))),
        DataCell(
          Chip(
            label: Text(band.label),
            backgroundColor: band.bg,
            side: BorderSide(color: band.fg.withValues(alpha: 0.4)),
          ),
        ),
        DataCell(_AlertsActions(item: item)),
      ],
    );
  }
}

class _AlertsActions extends StatelessWidget {
  const _AlertsActions({required this.item});

  final ExpiryAlertItem item;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.employeeProfile.replaceFirst(':id', item.employeeId)),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: Text(t.openProfile),
        ),
        if (item.type.startsWith('document:') && (item.fileUrl ?? '').trim().isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => _openDocument(context, item.fileUrl!),
            icon: const Icon(Icons.description_outlined, size: 16),
            label: Text(t.openDocument),
          ),
      ],
    );
  }

  Future<void> _openDocument(BuildContext context, String url) async {
    final t = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.invalidFileUrl)));
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.unableOpenFile)));
    }
  }
}
