import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/routing/app_routes.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../employees/domain/models/expiry_alert.dart';
import '../../../domain/models/hr_alert_state_info.dart';
import 'hr_alerts_table_utils.dart';

class HrAlertsTable extends StatelessWidget {
  const HrAlertsTable({
    super.key,
    required this.items,
    required this.stateByKey,
    required this.onHandled,
    required this.onSnooze,
    required this.onRestore,
  });

  final List<ExpiryAlertItem> items;
  final Map<String, HrAlertStateInfo> stateByKey;
  final ValueChanged<ExpiryAlertItem> onHandled;
  final ValueChanged<ExpiryAlertItem> onSnooze;
  final ValueChanged<ExpiryAlertItem> onRestore;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        child: Center(
          child: Text(AppLocalizations.of(context)!.hrAlertsNoRows),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(AppLocalizations.of(context)!.hrAlertsColEmployee)),
            DataColumn(label: Text(AppLocalizations.of(context)!.hrAlertsColType)),
            DataColumn(label: Text(AppLocalizations.of(context)!.hrAlertsColExpiryDate)),
            DataColumn(label: Text(AppLocalizations.of(context)!.hrAlertsColDaysLeft)),
            DataColumn(label: Text(AppLocalizations.of(context)!.hrAlertsColStatus)),
            DataColumn(label: Text(_followUpLabel(context))),
            DataColumn(label: Text(AppLocalizations.of(context)!.actions)),
          ],
          rows: items.map((item) => _buildRow(context, item)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, ExpiryAlertItem item) {
    final band = alertBand(context, item.daysLeft);
    final state = stateByKey[_stateKey(item)];
    return DataRow(
      color: WidgetStatePropertyAll(band.bg),
      cells: [
        DataCell(Text(item.employeeName)),
        DataCell(Text(alertTypeLabel(context, item.type))),
        DataCell(Text(formatAlertDate(item.expiryDate))),
        DataCell(
          Text(
            '${item.daysLeft}',
            style: TextStyle(color: band.fg, fontWeight: FontWeight.w700),
          ),
        ),
        DataCell(
          Chip(
            label: Text(band.label),
            backgroundColor: band.bg,
            side: BorderSide(color: band.fg.withValues(alpha: 0.4)),
          ),
        ),
        DataCell(_AlertStateChips(state: state)),
        DataCell(
          _AlertsActions(
            item: item,
            state: state,
            onHandled: onHandled,
            onSnooze: onSnooze,
            onRestore: onRestore,
          ),
        ),
      ],
    );
  }

  String _stateKey(ExpiryAlertItem item) =>
      '${item.employeeId}|${item.type}|${DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day).toIso8601String().split('T').first}';

  String _followUpLabel(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? 'المتابعة' : 'Follow-up';
  }
}

class _AlertsActions extends StatelessWidget {
  const _AlertsActions({
    required this.item,
    required this.state,
    required this.onHandled,
    required this.onSnooze,
    required this.onRestore,
  });

  final ExpiryAlertItem item;
  final HrAlertStateInfo? state;
  final ValueChanged<ExpiryAlertItem> onHandled;
  final ValueChanged<ExpiryAlertItem> onSnooze;
  final ValueChanged<ExpiryAlertItem> onRestore;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final hasFile = (item.fileUrl ?? '').trim().isNotEmpty;
    final alertState = state;

    return PopupMenuButton<_EmployeeAlertAction>(
      tooltip: isArabic ? 'إجراءات' : 'Actions',
      onSelected: (value) async {
        switch (value) {
          case _EmployeeAlertAction.openProfile:
            context.push(
              AppRoutes.employeeProfile.replaceFirst(':id', item.employeeId),
            );
            break;
          case _EmployeeAlertAction.openEmployeeDocs:
            final query = _employeeDocsQuery(item.type);
            context.push(
              query == null
                  ? '${AppRoutes.employeeDocs}?employeeId=${item.employeeId}'
                  : '${AppRoutes.employeeDocs}?employeeId=${item.employeeId}&docType=$query',
            );
            break;
          case _EmployeeAlertAction.renewDocument:
            await _handleRenew(context, item);
            break;
          case _EmployeeAlertAction.snooze:
            onSnooze(item);
            break;
          case _EmployeeAlertAction.handled:
            onHandled(item);
            break;
          case _EmployeeAlertAction.restore:
            onRestore(item);
            break;
          case _EmployeeAlertAction.openDocument:
            if (hasFile) {
              await _openDocument(context, item.fileUrl!);
            }
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _EmployeeAlertAction.openProfile,
          child: Text(isArabic ? 'فتح ملف الموظف' : 'Open Employee Profile'),
        ),
        PopupMenuItem(
          value: _EmployeeAlertAction.openEmployeeDocs,
          child: Text(isArabic ? 'فتح مستندات الموظف' : 'Open Employee Documents'),
        ),
        PopupMenuItem(
          value: _EmployeeAlertAction.renewDocument,
          child: Text(isArabic ? 'تجديد المستند' : 'Renew Document'),
        ),
        PopupMenuItem(
          value: _EmployeeAlertAction.snooze,
          child: Text(isArabic ? 'تأجيل 7 أيام' : 'Snooze 7 Days'),
        ),
        PopupMenuItem(
          value: _EmployeeAlertAction.handled,
          child: Text(isArabic ? 'تم التعامل معه' : 'Mark as Handled'),
        ),
        if (alertState != null &&
            (alertState.isHandled || alertState.isSnoozed))
          PopupMenuItem(
            value: _EmployeeAlertAction.restore,
            child: Text(isArabic ? 'استعادة التنبيه' : 'Restore Alert'),
          ),
        if (hasFile)
          PopupMenuItem(
            value: _EmployeeAlertAction.openDocument,
            child: Text(isArabic ? 'فتح المستند الحالي' : 'Open Current Document'),
          ),
      ],
    );
  }

  String? _employeeDocsQuery(String type) {
    if (type.startsWith('document:')) {
      return type.split(':').last;
    }
    switch (type) {
      case 'residency':
        return 'residency';
      case 'insurance':
        return 'insurance';
      default:
        return null;
    }
  }

  Future<void> _handleRenew(BuildContext context, ExpiryAlertItem item) async {
    if (item.type == 'contract') {
      final startDate = item.expiryDate.add(const Duration(days: 1));
      final endDate = DateTime(
        item.expiryDate.year + 1,
        item.expiryDate.month,
        item.expiryDate.day,
      );
      context.push(
        '${AppRoutes.employeeProfile.replaceFirst(':id', item.employeeId)}?openAddContract=1&contractStart=${startDate.toIso8601String()}&contractEnd=${endDate.toIso8601String()}&oldContractEnd=${item.expiryDate.toIso8601String()}',
      );
      return;
    }

    final renewType = _employeeDocsQuery(item.type);
    final issuedAt = DateTime.now().toIso8601String();
    final expiresAt = DateTime(
      item.expiryDate.year + 1,
      item.expiryDate.month,
      item.expiryDate.day,
    ).toIso8601String();
    final oldExpiresAt = item.expiryDate.toIso8601String();
    context.push(
      renewType == null
          ? '${AppRoutes.employeeDocs}?employeeId=${item.employeeId}&openCreate=1&issuedAt=$issuedAt&expiresAt=$expiresAt&oldExpiresAt=$oldExpiresAt'
          : '${AppRoutes.employeeDocs}?employeeId=${item.employeeId}&docType=$renewType&openCreate=1&issuedAt=$issuedAt&expiresAt=$expiresAt&oldExpiresAt=$oldExpiresAt',
    );
  }

  Future<void> _openDocument(BuildContext context, String url) async {
    final t = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.invalidFileUrl)),
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.unableOpenFile)),
      );
    }
  }
}

class _AlertStateChips extends StatelessWidget {
  const _AlertStateChips({required this.state});

  final HrAlertStateInfo? state;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final alertState = state;
    if (alertState == null || (!alertState.isHandled && !alertState.isSnoozed)) {
      return Text(
        '—',
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      );
    }

    final chips = <Widget>[];
    if (alertState.isHandled) {
      chips.add(
        Chip(
          label: Text(isArabic ? 'تم التعامل' : 'Handled'),
          backgroundColor: Colors.green.withValues(alpha: 0.12),
          side: BorderSide(color: Colors.green.withValues(alpha: 0.28)),
        ),
      );
    }
    if (alertState.isSnoozed) {
      final until = alertState.snoozeUntil!;
      chips.add(
        Chip(
          label: Text(
            isArabic
                ? 'مؤجل حتى ${until.year}-${until.month.toString().padLeft(2, '0')}-${until.day.toString().padLeft(2, '0')}'
                : 'Snoozed to ${until.year}-${until.month.toString().padLeft(2, '0')}-${until.day.toString().padLeft(2, '0')}',
          ),
          backgroundColor: Colors.blue.withValues(alpha: 0.12),
          side: BorderSide(color: Colors.blue.withValues(alpha: 0.28)),
        ),
      );
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}

enum _EmployeeAlertAction {
  openProfile,
  openEmployeeDocs,
  renewDocument,
  snooze,
  handled,
  restore,
  openDocument,
}
