import 'package:material_ui/material_ui.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../employees/domain/models/expiry_alert.dart';
import '../../../data/repos/hr_alerts_repo.dart' show employeeAlertKey;
import '../../../domain/models/hr_alerts_data.dart';
import 'hr_alerts_table.dart';
import 'hr_alerts_table_utils.dart';

class HrExpiryAlertsView extends StatefulWidget {
  const HrExpiryAlertsView({
    super.key,
    required this.data,
    this.initialType,
    required this.onSaveSettings,
    required this.onAdvancedSettings,
    required this.onHandled,
    required this.onSnooze,
    required this.onRestore,
  });
  final HrAlertsData data;
  final String? initialType;
  final Future<void> Function(ExpiryAlertSettings) onSaveSettings;
  final VoidCallback onAdvancedSettings;
  final ValueChanged<ExpiryAlertItem> onHandled, onSnooze, onRestore;
  @override
  State<HrExpiryAlertsView> createState() => _HrExpiryAlertsViewState();
}

class _HrExpiryAlertsViewState extends State<HrExpiryAlertsView> {
  static const purple = Color(0xFF8654BC),
      ink = Color(0xFF21194E),
      border = Color(0xFFECE6F4);
  final _form = GlobalKey<FormState>();
  late final TextEditingController _days;
  String? _type;
  String _expiry = 'all', _followUp = 'active';
  bool _saving = false;
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => ar ? a : e;
  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _days = TextEditingController(
      text: '${widget.data.settings.documentsAlertDays}',
    );
  }

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HrExpiryAlertsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_saving &&
        oldWidget.data.settings.documentsAlertDays !=
            widget.data.settings.documentsAlertDays) {
      _days.text = '${widget.data.settings.documentsAlertDays}';
    }
  }

  bool typeMatches(ExpiryAlertItem i) {
    if (_type == null) return true;
    if (_type == 'document') return i.type.startsWith('document:');
    return switch (_type) {
      'residency' => {'residency', 'document:residency'}.contains(i.type),
      'insurance' => {
        'insurance',
        'document:insurance',
        'document:medical_insurance',
      }.contains(i.type),
      'contract' => {'contract', 'document:contract'}.contains(i.type),
      _ => i.type == _type,
    };
  }

  Future<void> save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    final count = int.parse(_days.text.trim());
    setState(() {
      _saving = true;
    });
    try {
      await widget.onSaveSettings(
        ExpiryAlertSettings(
          contractAlertDays: count,
          residencyAlertDays: count,
          insuranceAlertDays: count,
          documentsAlertDays: count,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.hrAlertsSettingsSaved),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.saveFailed('$e')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scoped = widget.data.items.where(typeMatches).where((i) {
      final state = widget.data.employeeStates[employeeAlertKey(i)];
      return switch (_followUp) {
        'all' => true,
        'handled' => state?.isHandled == true,
        'snoozed' => state?.isSnoozed == true && state?.isHandled != true,
        _ => state?.isHandled != true && state?.isSnoozed != true,
      };
    }).toList();
    final filtered =
        scoped
            .where(
              (i) => switch (_expiry) {
                'expired' => i.daysLeft < 0,
                'soon' => i.daysLeft >= 0,
                _ => true,
              },
            )
            .toList()
          ..sort((a, b) {
            final n = a.daysLeft.compareTo(b.daysLeft);
            return n != 0 ? n : a.employeeName.compareTo(b.employeeName);
          });
    final knownTypes = <String, String>{
      'document': tr('المستندات', 'Documents'),
      'contract': t.hrTypeContract,
      'document:id_card': t.idCard,
      'residency': t.residencyDocument,
      'document:passport': t.passport,
      'insurance': t.medicalInsurance,
    };
    for (final i in widget.data.items) {
      knownTypes.putIfAbsent(i.type, () => alertTypeLabel(context, i.type));
    }
    if (_type != null) {
      knownTypes.putIfAbsent(_type!, () => alertTypeLabel(context, _type!));
    }
    Widget field(
      String key,
      String label,
      String? value,
      Map<String, String> options,
      ValueChanged<String?> changed, {
      bool all = true,
    }) => SizedBox(
      width: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: ink)),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            key: ValueKey(key),
            initialValue: value,
            isExpanded: true,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 13, color: ink),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: border),
              ),
              border: const OutlineInputBorder(),
            ),
            items: [
              if (all) DropdownMenuItem(value: null, child: Text(t.all)),
              for (final e in options.entries)
                DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _saving ? null : changed,
          ),
        ],
      ),
    );
    final settings = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAFF),
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: purple, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('إعدادات التنبيه', 'Alert settings'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              tr('إشعار قبل عدد الأيام', 'Notify before expiry (days)'),
              style: const TextStyle(fontSize: 13, color: ink),
            ),
            const SizedBox(height: 6),
            TextFormField(
              key: const ValueKey('alert-days'),
              controller: _days,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.start,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: border),
                ),
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                return n == null || n < 1 || n > 365
                    ? t.validationRange1To365
                    : null;
              },
            ),
            const SizedBox(height: 10),
            Text(
              tr(
                'يطبّق هذا العدد على العقود والإقامة والتأمين وجميع المستندات.',
                'Applies to contracts, residency, insurance and all documents.',
              ),
              style: const TextStyle(fontSize: 12, color: Color(0xFF77738C)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('save-alert-settings'),
              onPressed: _saving ? null : save,
              style: FilledButton.styleFrom(
                backgroundColor: purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(tr('حفظ الإعدادات', 'Save settings')),
            ),
            TextButton(
              onPressed: _saving ? null : widget.onAdvancedSettings,
              child: Text(
                tr('إعدادات حسب نوع التنبيه', 'Settings by alert type'),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
    Widget summary(String label, int count, bool expired) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: expired ? const Color(0xFFFFF2F3) : const Color(0xFFFFF8E8),
          border: Border.all(
            color: expired ? const Color(0xFFFFDEE3) : const Color(0xFFFFEDCB),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: expired
                          ? const Color(0xFFCF233C)
                          : const Color(0xFFB76108),
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: expired
                          ? const Color(0xFFCF233C)
                          : const Color(0xFFB76108),
                    ),
                  ),
                  Text(
                    expired
                        ? tr('مستندات منتهية', 'Expired records')
                        : tr(
                            'ضمن مدة التنبيه المحددة',
                            'Within the configured warning period',
                          ),
                    style: TextStyle(
                      fontSize: 12,
                      color: expired
                          ? const Color(0xFFCF233C)
                          : const Color(0xFFB76108),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: expired
                    ? const Color(0xFFFFDCDF)
                    : const Color(0xFFFFEAC0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                expired ? Icons.assignment_late_outlined : Icons.schedule,
                color: expired
                    ? const Color(0xFFE63249)
                    : const Color(0xFFBD710F),
              ),
            ),
          ],
        ),
      ),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            field(
              'alert-expiry-filter',
              tr('حالة التنبيه', 'Expiry status'),
              _expiry,
              {
                'all': t.all,
                'expired': tr('منتهي', 'Expired'),
                'soon': tr('قريب من الانتهاء', 'Near expiry'),
              },
              (v) => setState(() => _expiry = v!),
              all: false,
            ),
            field(
              'alert-type-$_type',
              tr('نوع التنبيه', 'Alert type'),
              _type,
              knownTypes,
              (v) => setState(() => _type = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in <(String?, String, IconData)>[
              (
                null,
                tr('جميع التنبيهات', 'All alerts'),
                Icons.notifications_active_outlined,
              ),
              ('document:id_card', t.idCard, Icons.badge_outlined),
              ('residency', t.residencyDocument, Icons.shield_outlined),
              ('document:passport', t.passport, Icons.travel_explore),
              (
                'insurance',
                t.medicalInsurance,
                Icons.health_and_safety_outlined,
              ),
              ('contract', t.contract, Icons.description_outlined),
            ])
              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () => setState(() => _type = option.$1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: purple,
                  backgroundColor: _type == option.$1
                      ? const Color(0xFFF0E5FF)
                      : const Color(0xFFFCFAFF),
                  side: BorderSide(color: _type == option.$1 ? purple : border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                icon: Icon(option.$3, size: 17),
                label: Text(option.$2, style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 550
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    summary(
                      tr('قريبة من الانتهاء', 'Near expiry'),
                      scoped.where((i) => i.daysLeft >= 0).length,
                      false,
                    ),
                    const SizedBox(width: 12),
                    summary(
                      tr('منتهية الصلاحية', 'Expired'),
                      scoped.where((i) => i.daysLeft < 0).length,
                      true,
                    ),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        summary(
                          tr('قريبة من الانتهاء', 'Near expiry'),
                          scoped.where((i) => i.daysLeft >= 0).length,
                          false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        summary(
                          tr('منتهية الصلاحية', 'Expired'),
                          scoped.where((i) => i.daysLeft < 0).length,
                          true,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final option in [
              ('active', tr('نشطة', 'Active')),
              ('all', tr('كل المتابعات', 'All follow-ups')),
              ('snoozed', tr('مؤجلة', 'Snoozed')),
              ('handled', tr('تم التعامل معها', 'Handled')),
            ])
              ChoiceChip(
                label: Text(option.$2, style: const TextStyle(fontSize: 12)),
                selected: _followUp == option.$1,
                onSelected: _saving
                    ? null
                    : (_) => setState(() => _followUp = option.$1),
                selectedColor: const Color(0xFFF0E5FF),
                side: const BorderSide(color: border),
              ),
          ],
        ),
        const SizedBox(height: 10),
        HrAlertsTable(
          filtered: _type != null || _expiry != 'all' || _followUp != 'all',
          onClear: _type != null || _expiry != 'all' || _followUp != 'all' ? () => setState(() { _type = null; _expiry = 'all'; _followUp = 'all'; }) : null,
          items: filtered,
          stateByKey: widget.data.employeeStates,
          onHandled: widget.onHandled,
          onSnooze: widget.onSnooze,
          onRestore: widget.onRestore,
        ),
      ],
    );
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth >= 950
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: c.maxWidth * .28, child: settings),
                  const SizedBox(width: 14),
                  Expanded(child: content),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [settings, const SizedBox(height: 14), content],
              ),
      ),
    );
  }
}
