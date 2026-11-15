import 'package:flutter/material.dart';
import 'package:erp_sys/core/ui/app_data_state.dart';
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
    this.filtered = false,
    this.onClear,
  });

  final List<GovernmentAlertItem> items;
  final Map<String, HrAlertStateInfo> stateById;
  final ValueChanged<GovernmentAlertItem> onEdit;
  final ValueChanged<GovernmentAlertItem> onRenew;
  final ValueChanged<GovernmentAlertItem> onDelete;
  final ValueChanged<GovernmentAlertItem> onHandled;
  final ValueChanged<GovernmentAlertItem> onSnooze;
  final ValueChanged<GovernmentAlertItem> onRestore;
  final bool filtered;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    Widget heading(String text) => Expanded(
      child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
    if (items.isEmpty) {
      return Card(
        child: Center(
          child: AppEmptyState(
            filtered: filtered,
            onClear: onClear,
            title: filtered
                ? null
                : (isArabic
                      ? 'لا توجد تنبيهات حكومية حاليًا.'
                      : 'No government alerts found.'),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        key: const ValueKey('government-table-frame'),
        width: constraints.maxWidth,
        height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: _GovernmentTableScroll(
            tableWidth: constraints.maxWidth.clamp(
              isArabic ? 1250.0 : 1450.0,
              double.infinity,
            ),
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 12,
              headingRowColor: const WidgetStatePropertyAll(Color(0xFFF4F0F8)),
              columns: [
                DataColumn(
                  columnWidth: const FlexColumnWidth(2.5),
                  label: heading(isArabic ? 'الاسم' : 'Name'),
                ),
                DataColumn(
                  columnWidth: const FlexColumnWidth(1.4),
                  label: heading(isArabic ? 'النوع' : 'Type'),
                ),
                DataColumn(
                  columnWidth: const FlexColumnWidth(1.3),
                  label: heading(isArabic ? 'تاريخ البداية' : 'Start Date'),
                ),
                DataColumn(
                  columnWidth: const FlexColumnWidth(1.3),
                  label: heading(isArabic ? 'تاريخ النهاية' : 'End Date'),
                ),
                DataColumn(
                  columnWidth: const FlexColumnWidth(1.2),
                  label: heading(
                    AppLocalizations.of(context)!.hrAlertsColDaysLeft,
                  ),
                ),
                DataColumn(
                  columnWidth: const FlexColumnWidth(1.5),
                  label: heading(
                    AppLocalizations.of(context)!.hrAlertsColStatus,
                  ),
                ),
                DataColumn(
                  columnWidth: const FlexColumnWidth(1.8),
                  label: heading(isArabic ? 'المتابعة' : 'Follow-up'),
                ),
                DataColumn(
                  columnWidth: const FixedColumnWidth(300),
                  label: heading(AppLocalizations.of(context)!.actions),
                ),
              ],
              rows: items
                  .map((item) => _buildRow(context, item, isArabic))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    GovernmentAlertItem item,
    bool isArabic,
  ) {
    final band = alertBand(context, item.daysLeft);
    final state = stateById[item.id];
    final alertState = state;
    final cells = <DataCell>[
      DataCell(
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              if ((item.description ?? '').trim().isNotEmpty)
                Text(
                  item.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: FilledButton.icon(
                key: ValueKey('government-renew-${item.id}'),
                onPressed: () => onRenew(item),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8654BC),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                icon: const Icon(Icons.autorenew, size: 16),
                label: Text(
                  isArabic ? 'تجديد' : 'Renew',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                key: ValueKey('government-view-${item.id}'),
                onPressed: () => (item.fileUrl ?? '').trim().isNotEmpty
                    ? _openFile(context, item.fileUrl!)
                    : _showDetails(context, item),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8654BC),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  side: const BorderSide(color: Color(0xFFE2D3F7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: Text(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  isArabic
                      ? ((item.fileUrl ?? '').trim().isNotEmpty
                            ? 'عرض المرفق'
                            : 'التفاصيل')
                      : ((item.fileUrl ?? '').trim().isNotEmpty
                            ? 'View attachment'
                            : 'Details'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            PopupMenuButton<_GovernmentAction>(
              key: ValueKey('government-menu-${item.id}'),
              tooltip: isArabic ? 'إجراءات' : 'Actions',
              onSelected: (value) async {
                switch (value) {
                  case _GovernmentAction.openFile:
                    final url = item.fileUrl;
                    if ((url ?? '').trim().isNotEmpty) {
                      await _openFile(context, url!);
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
          ],
        ),
      ),
    ];
    return DataRow(color: WidgetStatePropertyAll(band.bg), cells: cells);
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

  Future<void> _openFile(BuildContext context, String url) async {
    final t = AppLocalizations.of(context)!;
    try {
      final uri = Uri.tryParse(url);
      if (uri == null ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError(t.unableOpenFile);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.unableOpenFile)));
      }
    }
  }

  void _showDetails(BuildContext context, GovernmentAlertItem item) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final t = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.title),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_governmentTypeLabel(item.alertType, ar)),
                const SizedBox(height: 12),
                if ((item.description ?? '').trim().isNotEmpty) ...[
                  Text(item.description!),
                  const SizedBox(height: 12),
                ],
                Text(
                  '${ar ? 'تاريخ البداية' : 'Start date'}: ${formatAlertDate(item.startDate)}',
                ),
                Text(
                  '${ar ? 'تاريخ النهاية' : 'End date'}: ${formatAlertDate(item.endDate)}',
                ),
                const SizedBox(height: 12),
                Text(
                  ar
                      ? 'لا يوجد مرفق لهذا التنبيه.'
                      : 'No attachment for this alert.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.close)),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              onEdit(item);
            },
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text(t.edit),
          ),
        ],
      ),
    );
  }
}

class _GovernmentTableScroll extends StatefulWidget {
  const _GovernmentTableScroll({required this.tableWidth, required this.child});
  final double tableWidth;
  final Widget child;
  @override
  State<_GovernmentTableScroll> createState() => _GovernmentTableScrollState();
}

class _GovernmentTableScrollState extends State<_GovernmentTableScroll> {
  final _horizontal = ScrollController();
  final _vertical = ScrollController();
  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbColor: WidgetStatePropertyAll(
            const Color(0xFF8654BC).withValues(alpha: .8),
          ),
          trackColor: const WidgetStatePropertyAll(Color(0xFFF0E9F8)),
          trackBorderColor: const WidgetStatePropertyAll(Color(0xFFE2D3F7)),
          radius: const Radius.circular(5),
        ),
        child: Scrollbar(
          controller: _vertical,
          thumbVisibility: true,
          interactive: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.vertical,
          child: Scrollbar(
            key: const ValueKey('government-horizontal-scrollbar'),
            controller: _horizontal,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            thickness: 12,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            notificationPredicate: (notification) =>
                notification.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              key: const ValueKey('government-horizontal-scroll'),
              controller: _horizontal,
              primary: false,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: widget.tableWidth,
                height: constraints.hasBoundedHeight
                    ? constraints.maxHeight
                    : 400,
                child: SingleChildScrollView(
                  controller: _vertical,
                  primary: false,
                  padding: const EdgeInsets.only(bottom: 18, right: 12),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _GovernmentAlertStateChips extends StatelessWidget {
  const _GovernmentAlertStateChips({required this.state});

  final HrAlertStateInfo? state;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final alertState = state;
    if (alertState == null ||
        (!alertState.isHandled && !alertState.isSnoozed)) {
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

enum _GovernmentAction {
  openFile,
  edit,
  renew,
  snooze,
  handled,
  restore,
  delete,
}
