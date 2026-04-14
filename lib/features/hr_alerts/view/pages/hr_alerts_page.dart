import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../features/employees/domain/models/expiry_alert.dart';
import '../../data/repos/hr_alerts_repo.dart';
import '../../domain/models/government_alert_item.dart';
import '../../domain/models/government_alerts_summary.dart';
import '../../domain/models/hr_alert_state_info.dart';
import '../../domain/models/hr_alerts_data.dart';
import '../../domain/models/hr_alerts_summary.dart';
import '../widgets/government_alerts/government_alert_dialog.dart';
import '../widgets/government_alerts/government_alerts_table.dart';
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

class _HrAlertsPageState extends State<HrAlertsPage>
    with SingleTickerProviderStateMixin {
  final HrAlertsRepo _repo = HrAlertsRepo();
  late Future<HrAlertsData> _future;
  late TabController _tabController;
  String? _typeFilter;
  String _statusFilter = 'active';
  String _sortBy = 'urgency';

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.initialTypeFilter;
    _future = _repo.load(includeHidden: _shouldIncludeHidden);
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
      _future = _repo.load(includeHidden: _shouldIncludeHidden);
    });
  }

  bool get _shouldIncludeHidden => _statusFilter != 'active';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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
        }).where((item) {
          final state = data.employeeStates[_employeeStateKey(item)];
          return _matchesStatusFilter(state);
        }).toList()
          ..sort(_compareEmployeeAlerts);
        final filteredGovernmentItems = data.governmentItems.where((item) {
          final state = data.governmentStates[item.id];
          return _matchesStatusFilter(state);
        }).toList()
          ..sort(_compareGovernmentAlerts);
        final governmentAllCount = data.governmentItems.length;
        final governmentActiveCount = data.governmentItems
            .where((item) => _matchesStatusFilterFor('active', data.governmentStates[item.id]))
            .length;
        final governmentSnoozedCount = data.governmentItems
            .where((item) => _matchesStatusFilterFor('snoozed', data.governmentStates[item.id]))
            .length;
        final governmentHandledCount = data.governmentItems
            .where((item) => _matchesStatusFilterFor('handled', data.governmentStates[item.id]))
            .length;
        final typeScopedEmployeeItems = data.items.where((item) {
          if (_typeFilter == null) return true;
          if (_typeFilter == 'document') return item.type.startsWith('document:');
          return item.type == _typeFilter;
        }).toList();
        final allCount = typeScopedEmployeeItems.length;
        final activeCount = typeScopedEmployeeItems
            .where((item) => _matchesStatusFilterFor('active', data.employeeStates[_employeeStateKey(item)]))
            .length;
        final snoozedCount = typeScopedEmployeeItems
            .where((item) => _matchesStatusFilterFor('snoozed', data.employeeStates[_employeeStateKey(item)]))
            .length;
        final handledCount = typeScopedEmployeeItems
            .where((item) => _matchesStatusFilterFor('handled', data.employeeStates[_employeeStateKey(item)]))
            .length;
        final employeeSummary = HrAlertsSummary.fromItems(filteredItems);
        final governmentSummary = GovernmentAlertsSummary.fromItems(filteredGovernmentItems);
        final onGovernmentTab = _tabController.index == 1;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HrAlertsHeader(
                onRefresh: _reload,
                onSettings: () => _openSettings(data),
                onAddGovernmentAlert: _openGovernmentAlertDialog,
                showSettings: !onGovernmentTab,
                showAddGovernmentAlert: onGovernmentTab,
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  Tab(text: t.hrAlertsTitle),
                  Tab(text: isArabic ? 'تنبيهات الجهات' : 'Government Alerts'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HrAlertsFilters(
                          typeFilter: _typeFilter,
                          statusFilter: _statusFilter,
                          allCount: allCount,
                          activeCount: activeCount,
                          snoozedCount: snoozedCount,
                          handledCount: handledCount,
                          onTypeChanged: (value) {
                            setState(() {
                              _typeFilter = value;
                            });
                          },
                          onStatusChanged: (value) {
                            setState(() {
                              _statusFilter = value;
                              _future = _repo.load(includeHidden: _shouldIncludeHidden);
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
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            HrAlertsSummaryCard(
                              label: t.hrAlertsTotal,
                              value: '${employeeSummary.total}',
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            HrAlertsSummaryCard(
                              label: t.hrBandExpired,
                              value: '${employeeSummary.expired}',
                              color: Colors.red.shade700,
                            ),
                            HrAlertsSummaryCard(
                              label: t.hrBandUrgent,
                              value: '${employeeSummary.urgent}',
                              color: Colors.orange.shade700,
                            ),
                            HrAlertsSummaryCard(
                              label: t.hrTypeDocument,
                              value: '${employeeSummary.documents}',
                              color: Colors.indigo.shade700,
                            ),
                            HrAlertsSummaryCard(
                              label: t.hrTypeContract,
                              value: '${employeeSummary.contracts}',
                              color: Colors.teal.shade700,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: HrAlertsTable(
                            items: filteredItems,
                            stateByKey: data.employeeStates,
                            onHandled: _handleEmployeeAlert,
                            onSnooze: _snoozeEmployeeAlert,
                            onRestore: _restoreEmployeeAlert,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            HrAlertsSummaryCard(
                              label: isArabic ? 'إجمالي التنبيهات' : 'Total Alerts',
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
                              _future = _repo.load(includeHidden: _shouldIncludeHidden);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.hrAlertsSettingsSaved)),
      );
    } catch (e, st) {
      debugPrint('HR_ALERT_SETTINGS_SAVE_ERROR: $e');
      debugPrint('HR_ALERT_SETTINGS_SAVE_STACK: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.saveFailed('$e'))),
      );
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
        fileBytes: draft.fileBytes == null ? null : Uint8List.fromList(draft.fileBytes!),
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
            isArabic ? 'فشل حفظ التنبيه الحكومي' : 'Failed to save government alert',
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
        fileBytes: draft.fileBytes == null ? null : Uint8List.fromList(draft.fileBytes!),
        mimeType: draft.mimeType,
      );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'تم تحديث التنبيه' : 'Alert updated')),
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
        fileBytes: draft.fileBytes == null ? null : Uint8List.fromList(draft.fileBytes!),
        mimeType: draft.mimeType,
      );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'تم إنشاء نسخة مجددة من التنبيه' : 'Renewed alert created',
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
    final confirmed = await showDialog<bool>(
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
            isArabic ? 'تم إخفاء التنبيه بعد التعامل معه' : 'Alert marked as handled',
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
            isArabic ? 'فشل تحديث حالة التنبيه' : 'Failed to update alert state',
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
            isArabic ? 'تم إخفاء التنبيه بعد التعامل معه' : 'Alert marked as handled',
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
            isArabic ? 'فشل تحديث حالة التنبيه' : 'Failed to update alert state',
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
          content: Text(
            isArabic ? 'تمت استعادة التنبيه' : 'Alert restored',
          ),
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
          content: Text(
            isArabic ? 'تمت استعادة التنبيه' : 'Alert restored',
          ),
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

  String _employeeStateKey(ExpiryAlertItem item) {
    final date = DateTime(
      item.expiryDate.year,
      item.expiryDate.month,
      item.expiryDate.day,
    ).toIso8601String().split('T').first;
    return '${item.employeeId}|${item.type}|$date';
  }

  int _compareEmployeeAlerts(ExpiryAlertItem a, ExpiryAlertItem b) {
    switch (_sortBy) {
      case 'expiry_desc':
        return b.expiryDate.compareTo(a.expiryDate);
      case 'name':
        return a.employeeName.toLowerCase().compareTo(b.employeeName.toLowerCase());
      case 'expiry_asc':
        return a.expiryDate.compareTo(b.expiryDate);
      case 'urgency':
      default:
        final byDays = a.daysLeft.compareTo(b.daysLeft);
        if (byDays != 0) return byDays;
        return a.employeeName.toLowerCase().compareTo(b.employeeName.toLowerCase());
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
        Text(
          t.hrAlertsTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
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
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: Text(t.refresh),
        ),
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
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(t.retry),
          ),
        ],
      ),
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
      (
        key: 'all',
        label: isArabic ? 'كل الحالات' : 'All',
        count: allCount,
      ),
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
  const _AlertsSortBar({
    required this.value,
    required this.onChanged,
  });

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
