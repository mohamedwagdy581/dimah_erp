import 'package:erp_sys/core/ui/app_data_state.dart';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../features/employees/domain/models/expiry_alert.dart';
import '../../data/repos/hr_alerts_repo.dart';
import '../../domain/models/government_alert_item.dart';
import '../../domain/models/government_alerts_summary.dart';
import '../../domain/models/hr_alert_state_info.dart';
import '../../domain/models/hr_alerts_data.dart';
import '../widgets/government_alerts/government_alert_dialog.dart';
import '../widgets/government_alerts/government_alerts_table.dart';
import '../widgets/hr_alerts/hr_alerts_settings_dialog.dart';
import '../widgets/hr_alerts/hr_alerts_summary_card.dart';
import '../widgets/hr_alerts/hr_expiry_alerts_view.dart';

class HrAlertsPage extends StatefulWidget {
  const HrAlertsPage({super.key, this.initialTypeFilter, this.repo});

  final HrAlertsRepo? repo;

  final String? initialTypeFilter;

  @override
  State<HrAlertsPage> createState() => _HrAlertsPageState();
}

class _HrAlertsPageState extends State<HrAlertsPage>
    with SingleTickerProviderStateMixin {
  late final HrAlertsRepo _repo;
  late Future<HrAlertsData> _future;
  late TabController _tabController;
  String _statusFilter = 'all';
  String _sortBy = 'urgency';

  @override
  void initState() {
    super.initState();
    _repo = widget.repo ?? HrAlertsRepo();
    _future = _repo.load(includeHidden: true);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _repo.load(includeHidden: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return FutureBuilder<HrAlertsData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const AppLoadingState();
        }
        if (snap.hasError) {
          return AppFailureState(error: snap.error, onRetry: _reload);
        }

        final data = snap.data!;
        final filteredGovernmentItems = data.governmentItems.where((item) {
          final state = data.governmentStates[item.id];
          return _matchesStatusFilter(state);
        }).toList()..sort(_compareGovernmentAlerts);
        final governmentAllCount = data.governmentItems.length;
        final governmentActiveCount = data.governmentItems
            .where(
              (item) => _matchesStatusFilterFor(
                'active',
                data.governmentStates[item.id],
              ),
            )
            .length;
        final governmentSnoozedCount = data.governmentItems
            .where(
              (item) => _matchesStatusFilterFor(
                'snoozed',
                data.governmentStates[item.id],
              ),
            )
            .length;
        final governmentHandledCount = data.governmentItems
            .where(
              (item) => _matchesStatusFilterFor(
                'handled',
                data.governmentStates[item.id],
              ),
            )
            .length;
        final governmentSummary = GovernmentAlertsSummary.fromItems(
          filteredGovernmentItems,
        );
        final onGovernmentTab = _tabController.index == 1;

        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFECE6F4)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HrAlertsHeader(
                onRefresh: _reload,
                onSettings: () => _openSettings(data),
                onAddGovernmentAlert: _openGovernmentAlertDialog,
                showSettings: false,
                showAddGovernmentAlert: onGovernmentTab,
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  Tab(text: isArabic ? 'تنبيهات الانتهاء' : 'Expiry alerts'),
                  Tab(text: isArabic ? 'تنبيهات الجهات' : 'Government Alerts'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    HrExpiryAlertsView(
                      data: data,
                      initialType: widget.initialTypeFilter,
                      onSaveSettings: (settings) async {
                        await _repo.saveSettings(settings);
                        if (mounted) _reload();
                      },
                      onAdvancedSettings: () => _openSettings(data),
                      onHandled: _handleEmployeeAlert,
                      onSnooze: _snoozeEmployeeAlert,
                      onRestore: _restoreEmployeeAlert,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            HrAlertsSummaryCard(
                              label: isArabic
                                  ? 'إجمالي التنبيهات'
                                  : 'Total Alerts',
                              value: '${governmentSummary.total}',
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            HrAlertsSummaryCard(
                              label: t.hrBandExpired,
                              value: '${governmentSummary.expired}',
                              color: Colors.red.shade700,
                            ),
                            HrAlertsSummaryCard(
                              label: t.hrBandUrgent,
                              value: '${governmentSummary.urgent}',
                              color: Colors.orange.shade700,
                            ),
                            HrAlertsSummaryCard(
                              label: t.hrBandUpcoming,
                              value: '${governmentSummary.upcoming}',
                              color: Colors.amber.shade700,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _StatusScopeChips(
                          selected: _statusFilter,
                          allCount: governmentAllCount,
                          activeCount: governmentActiveCount,
                          snoozedCount: governmentSnoozedCount,
                          handledCount: governmentHandledCount,
                          onSelected: (value) {
                            setState(() {
                              _statusFilter = value;
                              _future = _repo.load(includeHidden: true);
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _AlertsSortBar(
                          value: _sortBy,
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: GovernmentAlertsTable(
                            filtered: _statusFilter != 'all',
                            onClear: _statusFilter != 'all'
                                ? () => setState(() => _statusFilter = 'all')
                                : null,
                            items: filteredGovernmentItems,
                            stateById: data.governmentStates,
                            onEdit: _editGovernmentAlert,
                            onRenew: _renewGovernmentAlert,
                            onDelete: _deleteGovernmentAlert,
                            onHandled: _handleGovernmentAlert,
                            onSnooze: _snoozeGovernmentAlert,
                            onRestore: _restoreGovernmentAlert,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
      _reload();
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

  Future<void> _openGovernmentAlertDialog() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final draft = await showGovernmentAlertDialog(context);
    if (draft == null) return;

    try {
      await _repo.createGovernmentAlert(
        title: draft.title,
        alertType: draft.alertType,
        startDate: draft.startDate,
        endDate: draft.endDate,
        description: draft.description,
        fileName: draft.fileName,
        fileBytes: draft.fileBytes == null
            ? null
            : Uint8List.fromList(draft.fileBytes!),
        mimeType: draft.mimeType,
      );
      if (!mounted) return;
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'تمت إضافة التنبيه الحكومي' : 'Government alert added',
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('GOV_ALERT_CREATE_ERROR: $e');
      debugPrint('GOV_ALERT_CREATE_STACK: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'فشل حفظ التنبيه الحكومي'
                : 'Failed to save government alert',
          ),
        ),
      );
    }
  }

  Future<void> _editGovernmentAlert(GovernmentAlertItem item) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final draft = await showEditGovernmentAlertDialog(
      context,
      title: isArabic ? 'تعديل التنبيه' : 'Edit Alert',
      submitLabel: isArabic ? 'حفظ التعديلات' : 'Save Changes',
      initialDraft: GovernmentAlertDraft(
        title: item.title,
        alertType: item.alertType,
        startDate: item.startDate,
        endDate: item.endDate,
        description: item.description,
        fileName: item.fileName,
      ),
    );
    if (draft == null) return;

    try {
      await _repo.updateGovernmentAlert(
        alertId: item.id,
        title: draft.title,
        alertType: draft.alertType,
        startDate: draft.startDate,
        endDate: draft.endDate,
        description: draft.description,
        existingFileName: item.fileName,
        existingFileUrl: item.fileUrl,
        fileName: draft.fileName,
        fileBytes: draft.fileBytes == null
            ? null
            : Uint8List.fromList(draft.fileBytes!),
        mimeType: draft.mimeType,
      );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'تم تحديث التنبيه' : 'Alert updated'),
        ),
      );
    } catch (e, st) {
      debugPrint('GOV_ALERT_UPDATE_ERROR: $e');
      debugPrint('GOV_ALERT_UPDATE_STACK: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'فشل تحديث التنبيه' : 'Failed to update alert',
          ),
        ),
      );
    }
  }

  Future<void> _renewGovernmentAlert(GovernmentAlertItem item) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final draft = await showEditGovernmentAlertDialog(
      context,
      title: isArabic ? 'تجديد / تمديد التنبيه' : 'Renew / Extend Alert',
      submitLabel: isArabic ? 'تجديد' : 'Renew',
      initialDraft: GovernmentAlertDraft(
        title: item.title,
        alertType: item.alertType,
        startDate: item.endDate.add(const Duration(days: 1)),
        endDate: item.endDate.add(const Duration(days: 365)),
        description: item.description,
        fileName: item.fileName,
      ),
    );
    if (draft == null) return;

    try {
      await _repo.createGovernmentAlert(
        title: draft.title,
        alertType: draft.alertType,
        startDate: draft.startDate,
        endDate: draft.endDate,
        description: draft.description,
        fileName: draft.fileName,
        fileBytes: draft.fileBytes == null
            ? null
            : Uint8List.fromList(draft.fileBytes!),
        mimeType: draft.mimeType,
      );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم إنشاء نسخة مجددة من التنبيه'
                : 'Renewed alert created',
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('GOV_ALERT_RENEW_ERROR: $e');
      debugPrint('GOV_ALERT_RENEW_STACK: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'فشل تجديد التنبيه' : 'Failed to renew alert',
          ),
        ),
      );
    }
  }

  Future<void> _deleteGovernmentAlert(GovernmentAlertItem item) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isArabic ? 'حذف التنبيه' : 'Delete Alert'),
            content: Text(
              isArabic
                  ? 'هل أنت متأكد من حذف هذا التنبيه؟'
                  : 'Are you sure you want to delete this alert?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(isArabic ? 'إلغاء' : 'Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(isArabic ? 'حذف' : 'Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    try {
      await _repo.deleteGovernmentAlert(item.id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'تم حذف التنبيه' : 'Alert deleted')),
      );
    } catch (e, st) {
      debugPrint('GOV_ALERT_DELETE_ERROR: $e');
      debugPrint('GOV_ALERT_DELETE_STACK: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'فشل حذف التنبيه' : 'Failed to delete alert',
          ),
        ),
      );
    }
  }

  Future<void> _handleEmployeeAlert(ExpiryAlertItem item) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      await _repo.markEmployeeAlertHandled(item);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم إخفاء التنبيه بعد التعامل معه'
                : 'Alert marked as handled',
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('HR_EMPLOYEE_ALERT_HANDLED_ERROR: $e');
      debugPrint('HR_EMPLOYEE_ALERT_HANDLED_STACK: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'فشل تحديث حالة التنبيه'
                : 'Failed to update alert state',
          ),
        ),
      );
    }
  }

  Future<void> _snoozeEmployeeAlert(ExpiryAlertItem item) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      await _repo.snoozeEmployeeAlert(item);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'تم تأجيل التنبيه 7 أيام' : 'Alert snoozed for 7 days',
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('HR_EMPLOYEE_ALERT_SNOOZE_ERROR: $e');
      debugPrint('HR_EMPLOYEE_ALERT_SNOOZE_STACK: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'فشل تأجيل التنبيه' : 'Failed to snooze alert',
          ),
        ),
      );
    }
  }

  Future<void> _handleGovernmentAlert(GovernmentAlertItem item) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      await _repo.markGovernmentAlertHandled(item.id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم إخفاء التنبيه بعد التعامل معه'
                : 'Alert marked as handled',
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('GOV_ALERT_HANDLED_ERROR: $e');
      debugPrint('GOV_ALERT_HANDLED_STACK: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'فشل تحديث حالة التنبيه'
                : 'Failed to update alert state',
          ),
        ),
      );
    }
  }

  Future<void> _snoozeGovernmentAlert(GovernmentAlertItem item) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      await _repo.snoozeGovernmentAlert(item.id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'تم تأجيل التنبيه 7 أيام' : 'Alert snoozed for 7 days',
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('GOV_ALERT_SNOOZE_ERROR: $e');
      debugPrint('GOV_ALERT_SNOOZE_STACK: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'فشل تأجيل التنبيه' : 'Failed to snooze alert',
          ),
        ),
      );
    }
  }

  Future<void> _restoreEmployeeAlert(ExpiryAlertItem item) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      await _repo.restoreEmployeeAlert(item);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'تمت استعادة التنبيه' : 'Alert restored'),
        ),
      );
    } catch (e, st) {
      debugPrint('HR_EMPLOYEE_ALERT_RESTORE_ERROR: $e');
      debugPrint('HR_EMPLOYEE_ALERT_RESTORE_STACK: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'فشل استعادة التنبيه' : 'Failed to restore alert',
          ),
        ),
      );
    }
  }

  Future<void> _restoreGovernmentAlert(GovernmentAlertItem item) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      await _repo.restoreGovernmentAlert(item.id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArabic ? 'تمت استعادة التنبيه' : 'Alert restored'),
        ),
      );
    } catch (e, st) {
      debugPrint('GOV_ALERT_RESTORE_ERROR: $e');
      debugPrint('GOV_ALERT_RESTORE_STACK: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'فشل استعادة التنبيه' : 'Failed to restore alert',
          ),
        ),
      );
    }
  }

  bool _matchesStatusFilter(HrAlertStateInfo? state) {
    return _matchesStatusFilterFor(_statusFilter, state);
  }

  bool _matchesStatusFilterFor(String filter, HrAlertStateInfo? state) {
    switch (filter) {
      case 'snoozed':
        return state?.isSnoozed ?? false;
      case 'handled':
        return state?.isHandled ?? false;
      case 'all':
        return true;
      case 'active':
      default:
        return !(state?.isHandled ?? false) && !(state?.isSnoozed ?? false);
    }
  }

  int _compareGovernmentAlerts(GovernmentAlertItem a, GovernmentAlertItem b) {
    switch (_sortBy) {
      case 'expiry_desc':
        return b.endDate.compareTo(a.endDate);
      case 'name':
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case 'expiry_asc':
        return a.endDate.compareTo(b.endDate);
      case 'urgency':
      default:
        final byDays = a.daysLeft.compareTo(b.daysLeft);
        if (byDays != 0) return byDays;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    }
  }
}

class _HrAlertsHeader extends StatelessWidget {
  const _HrAlertsHeader({
    required this.onRefresh,
    required this.onSettings,
    required this.onAddGovernmentAlert,
    required this.showSettings,
    required this.showAddGovernmentAlert,
  });

  final VoidCallback onRefresh;
  final VoidCallback onSettings;
  final VoidCallback onAddGovernmentAlert;
  final bool showSettings;
  final bool showAddGovernmentAlert;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'تنبيهات الانتهاء' : 'Expiry alerts',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF21194E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isArabic
                    ? 'متابعة المستندات والعقود التي قاربت على الانتهاء'
                    : 'Monitor expiring documents and contracts',
                style: const TextStyle(fontSize: 13, color: Color(0xFF77738C)),
              ),
            ],
          ),
        ),
        if (showSettings) ...[
          OutlinedButton.icon(
            onPressed: onSettings,
            icon: const Icon(Icons.tune),
            label: Text(t.hrAlertsSettings),
          ),
          const SizedBox(width: 8),
        ],
        if (showAddGovernmentAlert) ...[
          OutlinedButton.icon(
            onPressed: onAddGovernmentAlert,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(isArabic ? 'إضافة تنبيه' : 'Add Alert'),
          ),
          const SizedBox(width: 8),
        ],
        IconButton(
          onPressed: onRefresh,
          tooltip: t.refresh,
          icon: const Icon(Icons.refresh, color: Color(0xFF8654BC)),
        ),
      ],
    );
  }
}

class _StatusScopeChips extends StatelessWidget {
  const _StatusScopeChips({
    required this.selected,
    required this.allCount,
    required this.activeCount,
    required this.snoozedCount,
    required this.handledCount,
    required this.onSelected,
  });

  final String selected;
  final int allCount;
  final int activeCount;
  final int snoozedCount;
  final int handledCount;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final options = <({String key, String label, int count})>[
      (key: 'all', label: isArabic ? 'كل الحالات' : 'All', count: allCount),
      (
        key: 'active',
        label: isArabic ? 'النشطة' : 'Active',
        count: activeCount,
      ),
      (
        key: 'snoozed',
        label: isArabic ? 'المؤجلة' : 'Snoozed',
        count: snoozedCount,
      ),
      (
        key: 'handled',
        label: isArabic ? 'تم التعامل معها' : 'Handled',
        count: handledCount,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        return ChoiceChip(
          selected: selected == option.key,
          label: Text('${option.label} (${option.count})'),
          onSelected: (_) => onSelected(option.key),
        );
      }).toList(),
    );
  }
}

class _AlertsSortBar extends StatelessWidget {
  const _AlertsSortBar({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            isArabic ? 'ترتيب حسب' : 'Sort by',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
            items: [
              DropdownMenuItem(
                value: 'urgency',
                child: Text(isArabic ? 'الأكثر إلحاحًا' : 'Highest urgency'),
              ),
              DropdownMenuItem(
                value: 'expiry_asc',
                child: Text(isArabic ? 'الأقرب انتهاءً' : 'Nearest expiry'),
              ),
              DropdownMenuItem(
                value: 'expiry_desc',
                child: Text(isArabic ? 'الأبعد انتهاءً' : 'Farthest expiry'),
              ),
              DropdownMenuItem(
                value: 'name',
                child: Text(isArabic ? 'الاسم' : 'Name'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
