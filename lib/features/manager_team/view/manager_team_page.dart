import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_di.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/ui/employee_theme.dart';
import '../data/manager_team_repo.dart';
import '../domain/manager_team_data.dart';
import 'manager_team_cubit.dart';

part 'manager_team_tables.dart';

class ManagerTeamPage extends StatelessWidget {
  const ManagerTeamPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ManagerTeamCubit(SupabaseManagerTeamRepo(AppDI.supabase))..load(),
    child: const ManagerTeamView(),
  );
}

class ManagerTeamView extends StatefulWidget {
  const ManagerTeamView({super.key});
  @override
  State<ManagerTeamView> createState() => _ManagerTeamViewState();
}

class _ManagerTeamViewState extends State<ManagerTeamView> {
  final _membersKey = GlobalKey();
  final _tasksKey = GlobalKey();
  bool _allMembers = false;
  bool _showSearch = false;
  String _filter = 'upcoming';
  String _search = '';
  void _toggleMembers() => setState(() => _allMembers = !_allMembers);
  void _searchMembers(String value) => setState(() => _search = value);
  void _toggleSearch() => setState(() {
    _showSearch = !_showSearch;
    if (!_showSearch) _search = '';
  });
  void _changeFilter(String? value) {
    if (value != null) setState(() => _filter = value);
  }

  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String arabic, String english) => ar ? arabic : english;
  void _scroll(GlobalKey key) {
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  void _selectTasks(String filter) {
    setState(() => _filter = filter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scroll(_tasksKey);
      }
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ManagerTeamCubit, ManagerTeamState>(
    builder: (context, state) {
      if (state.loading) {
        return const AppLoadingState();
      }
      if (state.failed) {
        return AppFailureState(
          error: state.error,
          onRetry: context.read<ManagerTeamCubit>().load,
          title: tr('تعذر تحميل بيانات الفريق', 'Could not load your team'),
        );
      }
      final data = state.data!;
      final now = DateTime.now();
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: EmployeeTheme.primary.withValues(alpha: .12),
                child: const Icon(Icons.groups, color: EmployeeTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.managerName.isEmpty
                          ? tr('فريقي', 'My team')
                          : tr(
                              'أهلًا، ${data.managerName}',
                              'Welcome, ${data.managerName}',
                            ),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr(
                        data.departmentNames.isEmpty
                            ? 'متابعة أعضاء الفريق والمهام الموكلة إليهم'
                            : 'مدير ${data.departmentNames.join('، ')}',
                        data.departmentNames.isEmpty
                            ? 'Follow your team members and their assigned tasks'
                            : 'Manager · ${data.departmentNames.join(', ')}',
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      MaterialLocalizations.of(context).formatFullDate(now),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: tr('تحديث', 'Refresh'),
                onPressed: context.read<ManagerTeamCubit>().load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth >= 900
                  ? 4
                  : box.maxWidth >= 500
                  ? 2
                  : 1;
              final width = (box.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _stat(
                    width,
                    tr('طلبات معلّقة', 'Pending requests'),
                    data.pendingRequests,
                    Icons.inventory_2_rounded,
                    const Color(0xFF009B7B),
                    tr(
                      'طلبات الفريق بانتظار قرارك',
                      'Team requests awaiting your decision',
                    ),
                    tr('عرض الطلبات', 'View requests'),
                    () => context.go(AppRoutes.managerRequests),
                  ),
                  _stat(
                    width,
                    tr('في انتظار المراجعة', 'Awaiting review'),
                    data.reviews.length,
                    Icons.watch_later_rounded,
                    const Color(0xFF8661CF),
                    tr(
                      'طلبات مراجعة المهام من الفريق',
                      'Task review requests from your team',
                    ),
                    tr('عرض المراجعات', 'View reviews'),
                    () => _selectTasks('reviews'),
                  ),
                  _stat(
                    width,
                    tr('المهام المتأخرة', 'Overdue tasks'),
                    data.overdue(now).length,
                    Icons.article_rounded,
                    const Color(0xFFEF476F),
                    tr(
                      'مهام تجاوزت تاريخ الاستحقاق',
                      'Tasks past their due date',
                    ),
                    tr('عرض المهام', 'View tasks'),
                    () => _selectTasks('overdue'),
                  ),
                  _stat(
                    width,
                    tr('أفراد فريقي', 'Team members'),
                    data.members.length,
                    Icons.people_alt_rounded,
                    const Color(0xFF1685DE),
                    tr(
                      'الموظفون النشطون ضمن فريقك',
                      'Active employees in your team',
                    ),
                    tr('عرض الفريق', 'View team'),
                    () {
                      setState(() => _allMembers = true);
                      _scroll(_membersKey);
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          if (data.members.isEmpty)
            _panel(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppEmptyState(
                  title: tr(
                    'لا يوجد موظفون نشطون مرتبطون بفريقك حاليًا.',
                    'No active employees are currently linked to your team.',
                  ),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, box) {
                final members = _membersPanel(data);
                final tasks = _tasksPanel(data, now);
                if (box.maxWidth < 1000) {
                  return Column(
                    children: [members, const SizedBox(height: 16), tasks],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: members),
                    const SizedBox(width: 16),
                    Expanded(child: tasks),
                  ],
                );
              },
            ),
          const SizedBox(height: 16),
          Text(
            tr(
              'متوسط التقدم يشمل نسب جميع مهام الموظف، والمهمة المكتملة تُحسب 100%. اضغط تحديث لقراءة آخر التغييرات.',
              'Average progress includes all assigned tasks; completed tasks count as 100%. Refresh to load the latest changes.',
            ),
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    },
  );
  Widget _panel({required Widget child}) => Card(
    child: Padding(padding: const EdgeInsets.all(14), child: child),
  );
  Widget _stat(
    double width,
    String title,
    int value,
    IconData icon,
    Color color,
    String detail,
    String action,
    VoidCallback tap,
  ) => SizedBox(
    width: width,
    child: _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 23,
                backgroundColor: color.withValues(alpha: .08),
                child: Icon(icon, color: color, size: 25),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            thickness: .6,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: .4),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: tap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      action,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.swap_horiz_rounded, size: 17),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
