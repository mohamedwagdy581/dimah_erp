import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/government_alert_item.dart';
import '../../../domain/models/hr_alert_state_info.dart';
import '../hr_alerts/hr_alerts_table_utils.dart';

class GovernmentAlertsTable extends StatelessWidget {
  const GovernmentAlertsTable({
    super.key,
    required this.items,
    required this.stateById,
    required this.onEdit,
    required this.onRenew,
    required this.onDelete,
    required this.onHandled,
    required this.onSnooze,
    required this.onRestore,
  });

  final List<GovernmentAlertItem> items;
  final Map<String, HrAlertStateInfo> stateById;
  final ValueChanged<GovernmentAlertItem> onEdit;
  final ValueChanged<GovernmentAlertItem> onRenew;
  final ValueChanged<GovernmentAlertItem> onDelete;
  final ValueChanged<GovernmentAlertItem> onHandled;
  final ValueChanged<GovernmentAlertItem> onSnooze;
  final ValueChanged<GovernmentAlertItem> onRestore;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (items.isEmpty) {
      return Card(
        child: Center(
          child: Text(
            isArabic
                ? 'لا توجد تنبيهات حكومية حاليًا.'
                : 'No government alerts found.',
          ),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(isArabic ? 'الاسم' : 'Name')),
            DataColumn(label: Text(isArabic ? 'النوع' : 'Type')),
            DataColumn(label: Text(isArabic ? 'تاريخ البداية' : 'Start Date')),
            DataColumn(label: Text(isArabic ? 'تاريخ النهاية' : 'End Date')),
            DataColumn(label: Text(AppLocalizations.of(context)!.hrAlertsColDaysLeft)),
            DataColumn(label: Text(AppLocalizations.of(context)!.hrAlertsColStatus)),
            DataColumn(label: Text(isArabic ? 'المتابعة' : 'Follow-up')),
            DataColumn(label: Text(AppLocalizations.of(context)!.actions)),
          ],
          rows: items.map((item) => _buildRow(context, item, isArabic)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, GovernmentAlertItem item, bool isArabic) {
    final band = alertBand(context, item.daysLeft);
    final state = stateById[item.id];
    final alertState = state;
    return DataRow(
      color: WidgetStatePropertyAll(band.bg),
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.title),
              if ((item.description ?? '').trim().isNotEmpty)
                Text(
                  item.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        DataCell(Text(_governmentTypeLabel(item.alertType, isArabic))),
        DataCell(Text(formatAlertDate(item.startDate))),
        DataCell(Text(formatAlertDate(item.endDate))),
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
        DataCell(_GovernmentAlertStateChips(state: state)),
        DataCell(
          PopupMenuButton<_GovernmentAction>(
            tooltip: isArabic ? 'إجراءات' : 'Actions',
            onSelected: (value) async {
              switch (value) {
                case _GovernmentAction.openFile:
                  final url = item.fileUrl;
                  if ((url ?? '').trim().isNotEmpty) {
                    await _openFile(url!);
                  }
                  break;
                case _GovernmentAction.edit:
                  onEdit(item);
                  break;
                case _GovernmentAction.renew:
                  onRenew(item);
                  break;
                case _GovernmentAction.handled:
                  onHandled(item);
                  break;
                case _GovernmentAction.snooze:
                  onSnooze(item);
                  break;
                case _GovernmentAction.restore:
                  onRestore(item);
                  break;
                case _GovernmentAction.delete:
                  onDelete(item);
                  break;
              }
            },
            itemBuilder: (_) => [
              if ((item.fileUrl ?? '').trim().isNotEmpty)
                PopupMenuItem(
                  value: _GovernmentAction.openFile,
                  child: Text(isArabic ? 'فتح الملف' : 'Open File'),
                ),
              PopupMenuItem(
                value: _GovernmentAction.edit,
                child: Text(isArabic ? 'تعديل' : 'Edit'),
              ),
              PopupMenuItem(
                value: _GovernmentAction.renew,
                child: Text(isArabic ? 'تجديد / تمديد' : 'Renew / Extend'),
              ),
              PopupMenuItem(
                value: _GovernmentAction.snooze,
                child: Text(isArabic ? 'تأجيل 7 أيام' : 'Snooze 7 Days'),
              ),
              PopupMenuItem(
                value: _GovernmentAction.handled,
                child: Text(isArabic ? 'تم التعامل معه' : 'Mark as Handled'),
              ),
              if (alertState != null &&
                  (alertState.isHandled || alertState.isSnoozed))
                PopupMenuItem(
                  value: _GovernmentAction.restore,
                  child: Text(isArabic ? 'استعادة التنبيه' : 'Restore Alert'),
                ),
              PopupMenuItem(
                value: _GovernmentAction.delete,
                child: Text(isArabic ? 'حذف' : 'Delete'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _governmentTypeLabel(String type, bool isArabic) {
    switch (type) {
      case 'commercial_registration':
        return isArabic ? 'السجل التجاري' : 'Commercial Registration';
      case 'office_lease':
        return isArabic ? 'إيجار المكتب' : 'Office Lease';
      case 'medical_insurance':
        return isArabic ? 'التأمين الصحي' : 'Medical Insurance';
      case 'social_insurance':
        return isArabic ? 'التأمينات الاجتماعية' : 'Social Insurance';
      case 'qiwa_subscription':
        return isArabic ? 'اشتراك منصة قوى' : 'Qiwa Subscription';
      case 'mudad_subscription':
        return isArabic ? 'اشتراك منصة مدد' : 'Mudad Subscription';
      case 'muqeem_subscription':
        return isArabic ? 'اشتراك منصة مقيم' : 'Muqeem Subscription';
      default:
        return isArabic ? 'أخرى' : 'Other';
    }
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _GovernmentAlertStateChips extends StatelessWidget {
  const _GovernmentAlertStateChips({required this.state});

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

enum _GovernmentAction { openFile, edit, renew, snooze, handled, restore, delete }
