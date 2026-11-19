import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/ui/employee_theme.dart';
import '../../domain/models/notification_item.dart';

class EmployeeNotificationsView extends StatefulWidget {
  const EmployeeNotificationsView({
    super.key,
    required this.items,
    required this.onRefresh,
    this.loading = false,
    this.failed = false,
    this.error,
  });
  final List<NotificationItem> items;
  final VoidCallback onRefresh;
  final bool loading, failed;
  final Object? error;
  @override
  State<EmployeeNotificationsView> createState() =>
      _EmployeeNotificationsViewState();
}

class _EmployeeNotificationsViewState extends State<EmployeeNotificationsView> {
  String _filter = 'all', _search = '';
  final _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String a, String e) => ar ? a : e;
    final colors = Theme.of(context).colorScheme;
    final visible = widget.items
        .where(
          (item) =>
              (_filter == 'all' || item.category == _filter) &&
              '${item.title} ${item.subtitle}'.toLowerCase().contains(
                _search.toLowerCase().trim(),
              ),
        )
        .toList();
    Widget card(Widget child) => Card(
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: EmployeeTheme.primary.withValues(alpha: .12),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 27,
                color: EmployeeTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('إشعاراتي', 'My notifications'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    tr(
                      'تابع تحديثات مهامك وقرارات المراجعة في مكان واحد',
                      'Your task updates and review decisions in one place',
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: tr('تحديث', 'Refresh'),
              onPressed: widget.loading ? null : widget.onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 22),
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final group in [
                    ('all', tr('الكل', 'All')),
                    ('reviews', tr('المراجعات', 'Reviews')),
                    ('deadlines', tr('مواعيد المهام', 'Deadlines')),
                  ])
                    ChoiceChip(
                      selected: _filter == group.$1,
                      showCheckmark: false,
                      label: Text(
                        '${group.$2} (${group.$1 == 'all' ? widget.items.length : widget.items.where((i) => i.category == group.$1).length})',
                      ),
                      onSelected: (_) => setState(() => _filter = group.$1),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: tr(
                    'ابحث في إشعاراتك...',
                    'Search your notifications...',
                  ),
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  filled: true,
                  fillColor: colors.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.loading)
          const Padding(padding: EdgeInsets.all(40), child: AppLoadingState())
        else if (widget.failed)
          AppFailureState(error: widget.error, onRetry: widget.onRefresh)
        else if (visible.isEmpty)
          card(
            AppEmptyState(
              title: widget.items.isEmpty
                  ? tr('لا توجد إشعارات حاليًا', 'No notifications yet')
                  : tr('لا توجد إشعارات مطابقة', 'No matching notifications'),
              filtered: _filter != 'all' || _search.trim().isNotEmpty,
              onClear: _filter != 'all' || _search.trim().isNotEmpty
                  ? () => setState(() {
                      _filter = 'all';
                      _search = '';
                      _searchController.clear();
                    })
                  : null,
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              tr('آخر التحديثات', 'Latest updates'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          for (final item in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: card(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: item.color.withValues(alpha: .12),
                      child: Icon(item.icon, color: item.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          if (item.route != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton.icon(
                                onPressed: () => context.go(item.route!),
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: Text(tr('عرض التفاصيل', 'View details')),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
