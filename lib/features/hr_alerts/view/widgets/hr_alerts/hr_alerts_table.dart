import 'package:flutter/material.dart';
import 'package:erp_sys/core/ui/app_data_state.dart';
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
    this.filtered = false,
    this.onClear,
  });

  final List<ExpiryAlertItem> items;
  final Map<String, HrAlertStateInfo> stateByKey;
  final ValueChanged<ExpiryAlertItem> onHandled;
  final ValueChanged<ExpiryAlertItem> onSnooze;
  final ValueChanged<ExpiryAlertItem> onRestore;
  final bool filtered;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: AppEmptyState(
            filtered: filtered,
            onClear: onClear,
            title: filtered
                ? null
                : AppLocalizations.of(context)!.hrAlertsNoRows,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            headingRowHeight: 42,
            dataRowMinHeight: 44,
            dataRowMaxHeight: 48,
            columnSpacing: 18,
            horizontalMargin: 10,
            dividerThickness: 0,
            border: const TableBorder(
              horizontalInside: BorderSide(color: Color(0xFFECE6F4)),
              verticalInside: BorderSide(color: Color(0xFFF4EFFA)),
            ),
            headingRowColor: const WidgetStatePropertyAll(Color(0xFFF4F0F8)),
            headingTextStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 13,
              color: const Color(0xFF21194E),
            ),
            dataTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: const Color(0xFF21194E),
            ),
            columns: [
              DataColumn(
                label: Text(AppLocalizations.of(context)!.hrAlertsColEmployee),
              ),
              DataColumn(
                label: Text(AppLocalizations.of(context)!.hrAlertsColType),
              ),
              DataColumn(
                label: Text(
                  AppLocalizations.of(context)!.hrAlertsColExpiryDate,
                ),
              ),
              DataColumn(
                label: Text(AppLocalizations.of(context)!.hrAlertsColDaysLeft),
              ),
              DataColumn(
                label: Text(AppLocalizations.of(context)!.hrAlertsColStatus),
              ),
              DataColumn(label: Text(AppLocalizations.of(context)!.actions)),
            ],
            rows: items.map((item) => _buildRow(context, item)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, ExpiryAlertItem item) {
    final band = expiryAlertBand(context, item.daysLeft);
    final state = stateByKey[_stateKey(item)];
    return DataRow(
      cells: [
        DataCell(Text(item.employeeName)),
        DataCell(
          Text(
            item.type.startsWith('document:')
                ? documentTypeLabel(
                    AppLocalizations.of(context)!,
                    item.type.substring('document:'.length),
                  )
                : alertTypeLabel(context, item.type),
          ),
        ),
        DataCell(
          Text(
            formatAlertDate(item.expiryDate).replaceAll('-', '/'),
            textDirection: TextDirection.ltr,
          ),
        ),
        DataCell(
          Text(
            '${item.daysLeft.clamp(0, 1000000)}',
            style: TextStyle(color: band.fg, fontWeight: FontWeight.w700),
          ),
        ),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: band.bg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  band.label,
                  style: TextStyle(fontSize: 12, color: band.fg),
                ),
              ),
              if (state?.isHandled == true || state?.isSnoozed == true)
                Text(
                  state?.isHandled == true
                      ? (Localizations.localeOf(context).languageCode == 'ar'
                            ? 'تم التعامل'
                            : 'Handled')
                      : (Localizations.localeOf(context).languageCode == 'ar'
                            ? 'مؤجل'
                            : 'Snoozed'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF77738C),
                  ),
                ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AlertsActions(
                item: item,
                state: state,
                onHandled: onHandled,
                onSnooze: onSnooze,
                onRestore: onRestore,
                primary: true,
              ),
              _AlertsActions(
                item: item,
                state: state,
                onHandled: onHandled,
                onSnooze: onSnooze,
                onRestore: onRestore,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _stateKey(ExpiryAlertItem item) =>
      '${item.employeeId}|${item.type}|${DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day).toIso8601String().split('T').first}';
}

class _AlertsActions extends StatelessWidget {
  const _AlertsActions({
    required this.item,
    required this.state,
    required this.onHandled,
    required this.onSnooze,
    required this.onRestore,
    this.primary = false,
  });

  final ExpiryAlertItem item;
  final HrAlertStateInfo? state;
  final ValueChanged<ExpiryAlertItem> onHandled;
  final ValueChanged<ExpiryAlertItem> onSnooze;
  final ValueChanged<ExpiryAlertItem> onRestore;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final hasFile = (item.fileUrl ?? '').trim().isNotEmpty;
    final alertState = state;
    if (primary) {
      final renew = item.daysLeft < 0;
      final label = Text(
        isArabic
            ? (renew ? 'تجديد المستند' : 'عرض الموظف')
            : (renew ? 'Renew document' : 'View employee'),
        style: const TextStyle(fontSize: 12),
      );
      void action() {
        if (renew) {
          _handleRenew(context, item);
        } else {
          context.push(
            AppRoutes.employeeProfile.replaceFirst(':id', item.employeeId),
          );
        }
      }

      return renew
          ? FilledButton(
              onPressed: action,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8654BC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: label,
            )
          : OutlinedButton(
              onPressed: action,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8654BC),
                side: const BorderSide(color: Color(0xFFE2D3F7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: label,
            );
    }

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
          child: Text(
            isArabic ? 'فتح مستندات الموظف' : 'Open Employee Documents',
          ),
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
            child: Text(
              isArabic ? 'فتح المستند الحالي' : 'Open Current Document',
            ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.invalidFileUrl)));
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.unableOpenFile)));
    }
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
