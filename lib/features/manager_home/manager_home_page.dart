import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/app_di.dart';
import '../../core/routing/app_routes.dart';
import '../../core/ui/employee_theme.dart';
import '../manager_team/data/manager_team_repo.dart';
import '../manager_team/view/manager_team_cubit.dart';

class ManagerHomePage extends StatelessWidget {
  const ManagerHomePage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ManagerTeamCubit(SupabaseManagerTeamRepo(AppDI.supabase))..load(),
    child: const ManagerHomeView(),
  );
}

class ManagerHomeView extends StatelessWidget {
  const ManagerHomeView({super.key, this.now});
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String a, String e) => ar ? a : e;
    final colors = Theme.of(context).colorScheme;
    final today = now ?? DateTime.now();
    Widget panel(Widget child) => Card(
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
    void open(String path) => context.go(path);
    Widget title(String label, String route) => Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(
          onPressed: () => open(route),
          child: Text(tr('عرض الكل', 'View all')),
        ),
      ],
    );
    return BlocBuilder<ManagerTeamCubit, ManagerTeamState>(
      builder: (context, state) {
        if (state.loading) {
          return const AppLoadingState();
        }
        if (state.failed) {
          return AppFailureState(
            error: state.error,
            onRetry: context.read<ManagerTeamCubit>().load,
            title: tr(
              'تعذر تحميل ملخص الفريق',
              'Could not load your team summary',
            ),
          );
        }
        final data = state.data!;
        Widget metric(
          String label,
          int value,
          String caption,
          IconData icon,
          Color color,
          String route,
          String action,
        ) => panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: .1),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                caption,
                style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Divider(color: colors.outlineVariant.withValues(alpha: .45)),
              TextButton.icon(
                onPressed: () => open(route),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(action),
              ),
            ],
          ),
        );
        final metrics = [
          metric(
            tr('طلبات معلقة', 'Pending requests'),
            data.pendingRequests,
            tr(
              'طلبات الفريق بانتظار قرارك',
              'Team requests awaiting your decision',
            ),
            Icons.assignment,
            const Color(0xFF00A381),
            AppRoutes.managerRequests,
            tr('عرض الطلبات', 'View requests'),
          ),
          metric(
            tr('في انتظار المراجعة', 'Awaiting review'),
            data.tasks.where((t) => t.reviewPending || t.qaPending).length,
            tr(
              'مهام الفريق بانتظار مراجعتك',
              'Team tasks awaiting your review',
            ),
            Icons.schedule,
            const Color(0xFF7655E8),
            AppRoutes.managerReviews,
            tr('مراجعة التسليمات', 'Review submissions'),
          ),
          metric(
            tr('المهام المتأخرة', 'Overdue tasks'),
            data.overdue(today).length,
            tr('مهام تجاوزت تاريخ الاستحقاق', 'Tasks past their due date'),
            Icons.assignment_late,
            const Color(0xFFEF496C),
            AppRoutes.managerTeam,
            tr('عرض مهام الفريق', 'View team tasks'),
          ),
          metric(
            tr('أفراد فريقي', 'Team members'),
            data.members.length,
            tr('أعضاء الفريق النشطون', 'Active team members'),
            Icons.groups,
            const Color(0xFF0788E9),
            AppRoutes.managerTeam,
            tr('عرض الفريق', 'View team'),
          ),
        ];
        Widget workload() => panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title(
                tr('توزيع عبء العمل على الفريق', 'Team workload'),
                AppRoutes.managerTeam,
              ),
              const SizedBox(height: 12),
              if (data.members.isEmpty)
                Text(tr('لا يوجد أعضاء في الفريق', 'No team members')),
              for (final member in data.members.take(6)) ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: EmployeeTheme.primary.withValues(
                        alpha: .14,
                      ),
                      child: Text(
                        member.name.trim().isEmpty
                            ? '—'
                            : member.name.trim().substring(0, 1),
                        style: const TextStyle(color: EmployeeTheme.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        member.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${data.tasksFor(member.id).where((t) => !t.done).length}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: data.averageProgress(member.id),
                          minHeight: 7,
                          color: const Color(0xFF00A381),
                          backgroundColor: colors.outlineVariant.withValues(
                            alpha: .3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${(data.averageProgress(member.id) * 100).round()}%',
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 7),
                  child: Divider(height: 1),
                ),
              ],
              Text(
                tr(
                  'العدد: المهام النشطة • الشريط: متوسط تقدم المهام',
                  'Count: active tasks • Bar: average task progress',
                ),
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        );
        final upcoming = data.upcoming(today).take(5).toList();
        Widget tasks() => panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title(
                tr('المهام القادمة لفريقي', 'Upcoming team tasks'),
                AppRoutes.managerTeam,
              ),
              const SizedBox(height: 12),
              if (upcoming.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    tr(
                      'لا توجد مهام مستحقة خلال ٧ أيام',
                      'No tasks due within 7 days',
                    ),
                  ),
                ),
              for (final task in upcoming) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.priority == 'high'
                            ? const Color(0xFFEF496C)
                            : task.priority == 'low'
                            ? const Color(0xFF0788E9)
                            : const Color(0xFFFFA000),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            data.nameFor(task.employeeId),
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            MaterialLocalizations.of(
                              context,
                            ).formatCompactDate(task.due!),
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
              ],
            ],
          ),
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
                    Icons.groups,
                    color: EmployeeTheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.managerName.isEmpty
                            ? tr('أهلًا بك', 'Welcome')
                            : tr(
                                'أهلًا ${data.managerName}',
                                'Welcome ${data.managerName}',
                              ),
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (data.departmentNames.isNotEmpty)
                        Text(
                          data.departmentNames.join(' • '),
                          style: TextStyle(
                            fontSize: 15,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        MaterialLocalizations.of(context).formatFullDate(today),
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
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
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, box) {
                final count = box.maxWidth >= 1100
                    ? 4
                    : box.maxWidth >= 600
                    ? 2
                    : 1;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final item in metrics)
                      SizedBox(
                        width: (box.maxWidth - 14 * (count - 1)) / count,
                        child: item,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, box) => box.maxWidth < 900
                  ? Column(
                      children: [
                        workload(),
                        const SizedBox(height: 16),
                        tasks(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: workload()),
                        const SizedBox(width: 16),
                        Expanded(child: tasks()),
                      ],
                    ),
            ),
            const SizedBox(height: 18),
            panel(
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () => open(AppRoutes.managerTasks),
                    icon: const Icon(Icons.add_task),
                    label: Text(tr('إسناد مهمة جديدة', 'Assign a task')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => open(AppRoutes.managerAttendance),
                    icon: const Icon(Icons.calendar_month),
                    label: Text(tr('حضور الفريق', 'Team attendance')),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
