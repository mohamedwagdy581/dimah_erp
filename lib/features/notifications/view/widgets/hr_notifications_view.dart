import 'package:erp_sys/core/ui/app_data_state.dart';
import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/notification_item.dart';

const _ink = Color(0xFF21194E), _purple = Color(0xFF8654BC);
const _border = Color(0xFFE8E2F4), _muted = Color(0xFF777098);

class HrNotificationsView extends StatefulWidget {
  const HrNotificationsView({
    super.key,
    required this.items,
    required this.scope,
    required this.onRefresh,
    this.loading = false,
    this.failed = false,
    this.error,
  });
  final List<NotificationItem> items;
  final String scope;
  final VoidCallback onRefresh;
  final bool loading, failed;
  final Object? error;
  @override
  State<HrNotificationsView> createState() => _HrNotificationsViewState();
}

class _HrNotificationsViewState extends State<HrNotificationsView> {
  final _horizontal = ScrollController();
  final _vertical = ScrollController();
  final _read = <String>{};
  bool _unreadOnly = false, _ready = false, _savingRead = false;
  String get _storageKey => 'hr_notification_reads_v1:${widget.scope}';
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => ar ? a : e;
  String _id(NotificationItem item) =>
      item.id ??
      '${item.category}:${item.title}:${item.subtitle}:${item.occurredAt}';
  @override
  void initState() {
    super.initState();
    _loadRead();
  }

  Future<void> _loadRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      _read.addAll(prefs.getStringList(_storageKey) ?? []);
    } catch (_) {
      // The feed stays usable when local preferences are unavailable.
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  Future<void> _details(NotificationItem item) async {
    if (_savingRead) return;
    final id = _id(item);
    if (!_read.contains(id)) {
      setState(() {
        _read.add(id);
        _savingRead = true;
      });
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!await prefs.setStringList(_storageKey, _read.toList())) {
          throw StateError('Read state unavailable');
        }
      } catch (_) {
        _read.remove(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr(
                  'تعذر حفظ حالة القراءة على هذا الجهاز',
                  'Could not save read status on this device',
                ),
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _savingRead = false);
      }
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          item.title,
          style: const TextStyle(
            color: _ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
                if (item.occurredAt != null) ...[
                  const SizedBox(height: 16),
                  Text(_date(item.occurredAt)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr('إغلاق', 'Close')),
          ),
          if (item.route != null)
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go(item.route!);
              },
              icon: Icon(
                ar ? Icons.arrow_back : Icons.arrow_forward,
                textDirection: TextDirection.ltr,
                size: 17,
              ),
              label: Text(tr('الانتقال للشاشة', 'Open related page')),
            ),
        ],
      ),
    );
  }

  String _date(DateTime? value) {
    if (value == null) return '—';
    final d = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)}\n${two(d.hour)}:${two(d.minute)}';
  }

  (String, Color, IconData) _type(
    NotificationItem item,
  ) => switch (item.category) {
    'leave' => (
      tr('إجازة', 'Leave'),
      const Color(0xFF008B72),
      Icons.calendar_month_outlined,
    ),
    'documents' => (
      tr('مستندات', 'Documents'),
      const Color(0xFFFF8500),
      Icons.description_outlined,
    ),
    'payroll' => (tr('رواتب', 'Payroll'), _purple, Icons.receipt_long_outlined),
    'reviews' => (tr('مراجعة', 'Review'), _purple, Icons.fact_check_outlined),
    _ => (
      tr('مهمة', 'Task'),
      const Color(0xFF2866DD),
      Icons.assignment_outlined,
    ),
  };
  Widget _tab(String label, bool selected, VoidCallback onTap) => SizedBox(
    width: 145,
    height: 38,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFF9870C6), Color(0xFF7E4CB2)],
              )
            : null,
        color: selected ? null : const Color(0xFFFCFAFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _border),
      ),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: selected ? Colors.white : _ink,
          textStyle: TextStyle(
            fontFamily:
                Theme.of(context).textTheme.bodyMedium?.fontFamily ?? 'Roboto',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final unread = widget.items.where((i) => !_read.contains(_id(i))).length;
      final visible = widget.items
          .where((i) => !_unreadOnly || !_read.contains(_id(i)))
          .toList();
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('الإشعارات', 'Notifications'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          tr(
                            'متابعة الإشعارات والتنبيهات المتعلقة بمهامك',
                            'Follow notifications and updates related to your work',
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: _muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.loading ? null : widget.onRefresh,
                    tooltip: tr('تحديث', 'Refresh'),
                    icon: const Icon(Icons.refresh, color: _purple),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  textDirection: TextDirection.ltr,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _tab(
                      tr(
                        'الكل (${widget.items.length})',
                        'All (${widget.items.length})',
                      ),
                      !_unreadOnly,
                      () => setState(() => _unreadOnly = false),
                    ),
                    _tab(
                      tr('غير مقروء ($unread)', 'Unread ($unread)'),
                      _unreadOnly,
                      () => setState(() => _unreadOnly = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: widget.loading || !_ready
                    ? const AppLoadingState()
                    : widget.failed
                    ? AppFailureState(
                        error: widget.error,
                        onRetry: widget.onRefresh,
                      )
                    : visible.isEmpty
                    ? AppEmptyState(
                        title: tr(
                          _unreadOnly
                              ? 'لا توجد إشعارات غير مقروءة'
                              : 'لا توجد إشعارات حاليًا',
                          _unreadOnly
                              ? 'No unread notifications'
                              : 'No notifications yet',
                        ),
                        filtered: _unreadOnly,
                        onClear: _unreadOnly
                            ? () => setState(() => _unreadOnly = false)
                            : null,
                      )
                    : _table(visible),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _table(List<NotificationItem> items) => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.max(900.0, constraints.maxWidth);
      const flexes = [5, 17, 45, 17, 16];
      Widget cell(Widget child, {bool start = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Align(
          alignment: start
              ? AlignmentDirectional.centerStart
              : Alignment.center,
          child: child,
        ),
      );
      Widget row(List<Widget> cells, {bool header = false}) => Container(
        constraints: BoxConstraints(minHeight: header ? 54 : 100),
        decoration: BoxDecoration(
          color: header ? const Color(0xFFF5F5FB) : Colors.white,
          border: const Border(bottom: BorderSide(color: _border)),
        ),
        child: Row(
          children: List.generate(
            5,
            (i) => Expanded(flex: flexes[i], child: cells[i]),
          ),
        ),
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: _border)),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: Scrollbar(
              controller: _horizontal,
              thumbVisibility: true,
              trackVisibility: true,
              interactive: true,
              thickness: 10,
              scrollbarOrientation: ScrollbarOrientation.bottom,
              notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                key: const ValueKey('hr-notifications-horizontal'),
                controller: _horizontal,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      row([
                        cell(
                          const Text(
                            '#',
                            style: TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        cell(
                          Text(
                            tr('نوع الإشعار', 'Type'),
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        cell(
                          Text(
                            tr('العنوان', 'Title'),
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          start: true,
                        ),
                        cell(
                          Text(
                            tr('التاريخ والوقت', 'Date and time'),
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(),
                      ], header: true),
                      Expanded(
                        child: Scrollbar(
                          controller: _vertical,
                          thumbVisibility: true,
                          interactive: true,
                          notificationPredicate: (n) =>
                              n.metrics.axis == Axis.vertical,
                          child: ListView.builder(
                            controller: _vertical,
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: items.length,
                            itemBuilder: (_, index) {
                              final item = items[index],
                                  kind = _type(items[index]);
                              final unread = !_read.contains(_id(item));
                              return row([
                                cell(
                                  Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: _ink,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                cell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kind.$2.withValues(alpha: .1),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(kind.$3, size: 17, color: kind.$2),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            kind.$1,
                                            style: TextStyle(
                                              color: kind.$2,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                cell(
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            color: _ink,
                                            fontSize: 14,
                                            fontWeight: unread
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.subtitle,
                                          style: const TextStyle(
                                            color: _muted,
                                            fontSize: 12,
                                            height: 1.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  start: true,
                                ),
                                cell(
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _date(item.occurredAt),
                                          textDirection: TextDirection.ltr,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: _ink,
                                            fontSize: 12,
                                            height: 1.6,
                                          ),
                                        ),
                                      ),
                                      if (unread)
                                        const Padding(
                                          padding: EdgeInsetsDirectional.only(
                                            start: 6,
                                          ),
                                          child: Icon(
                                            Icons.circle,
                                            size: 7,
                                            color: Color(0xFF6236E8),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                cell(
                                  OutlinedButton.icon(
                                    iconAlignment: IconAlignment.end,
                                    key: ValueKey(
                                      'notification-details-${_id(item)}',
                                    ),
                                    onPressed: _savingRead
                                        ? null
                                        : () => _details(item),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF7934EE),
                                      backgroundColor: const Color(0xFFFAF6FF),
                                      side: const BorderSide(
                                        color: Color(0xFFE4D5FF),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    icon: Icon(
                                      ar
                                          ? Icons.arrow_back
                                          : Icons.arrow_forward,
                                      textDirection: TextDirection.ltr,
                                      size: 15,
                                    ),
                                    label: Text(
                                      tr('عرض التفاصيل', 'View details'),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ),
                              ]);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
