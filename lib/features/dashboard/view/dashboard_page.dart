import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/app_di.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/session/session_cubit.dart';
import '../../../l10n/app_localizations.dart';

part 'dashboard_page_hr_view_part.dart';
part 'dashboard_page_hr_data_part.dart';
part 'dashboard_page_hr_models_part.dart';
part 'dashboard_page_hr_cards_part.dart';
part 'dashboard_page_hr_actions_part.dart';
part 'dashboard_page_hr_workflow_part.dart';
part 'dashboard_page_hr_insight_panel_part.dart';
part 'dashboard_page_hr_sections_part.dart';
part 'dashboard_page_hr_layout_part.dart';
part 'dashboard_page_hr_insights_part.dart';
part 'dashboard_page_hr_helpers_part.dart';
part 'dashboard_page_hr_attendance_helpers_part.dart';
part 'dashboard_page_hr_document_helpers_part.dart';
part 'dashboard_page_shared_part.dart';
part 'dashboard_page_manager_part.dart';
part 'dashboard_page_manager_assign_part.dart';
part 'dashboard_page_manager_task_type_helpers_part.dart';
part 'dashboard_page_manager_catalog_part.dart';
part 'dashboard_page_manager_templates_part.dart';
part 'dashboard_page_manager_weights_part.dart';
part 'dashboard_page_manager_load_part.dart';
part 'dashboard_page_manager_metrics_part.dart';
part 'dashboard_page_manager_aggregates_part.dart';
part 'dashboard_page_manager_monthly_part.dart';
part 'dashboard_page_manager_timeline_helpers_part.dart';
part 'dashboard_page_manager_timeline_dialog_part.dart';
part 'dashboard_page_manager_timeline_data_part.dart';
part 'dashboard_page_manager_qa_dialog_part.dart';
part 'dashboard_page_manager_review_dialog_ui_part.dart';
part 'dashboard_page_manager_review_dialog_submit_part.dart';
part 'dashboard_page_manager_review_dialog_content_part.dart';
part 'dashboard_page_manager_summary_section_part.dart';
part 'dashboard_page_manager_team_section_part.dart';
part 'dashboard_page_manager_overview_part.dart';
part 'dashboard_page_manager_review_sections_part.dart';
part 'dashboard_page_manager_pending_review_part.dart';
part 'dashboard_page_manager_assign_widgets_part.dart';
part 'dashboard_page_manager_simple_list_part.dart';
part 'dashboard_page_manager_attachment_wrap_part.dart';
part 'dashboard_page_employee_view_part.dart';
part 'dashboard_page_employee_sections_part.dart';
part 'dashboard_page_employee_data_part.dart';
part 'dashboard_page_employee_notifications_part.dart';
part 'dashboard_page_manager_widgets_part.dart';
part 'dashboard_page_dashboard_data_part.dart';
part 'dashboard_page_task_models_part.dart';
part 'dashboard_page_chart_trend_cards_part.dart';
part 'dashboard_page_chart_distribution_part.dart';
part 'dashboard_page_chart_widgets_part.dart';
part 'dashboard_page_chart_painter_part.dart';
part 'dashboard_page_progress_circle_part.dart';
part 'dashboard_page_progress_bars_part.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        if (state is! SessionReady) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = state.user;
        if (user.role == 'hr') {
          return const _HrDashboard();
        }
        if ((user.role == 'manager' || user.role == 'direct_manager') &&
            user.employeeId != null) {
          return _ManagerDashboard(managerEmployeeId: user.employeeId!);
        }
        if (user.role == 'employee' && user.employeeId != null) {
          return _EmployeeDashboard(employeeId: user.employeeId!);
        }
        return _BackOfficeDashboard(title: t.menuDashboard);
      },
    );
  }
}

class _BackOfficeDashboard extends StatelessWidget {
  const _BackOfficeDashboard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(title));
  }
}
