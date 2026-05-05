import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/app_di.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/session/session_cubit.dart';
import '../../../l10n/app_localizations.dart';

part 'dashboard_view_body.dart';
part 'hr/dashboard_hr.dart';
part 'hr/dashboard_hr_body.dart';
part 'hr/sections/hr_dashboard_attendance_section.dart';
part 'hr/sections/hr_dashboard_header_section.dart';
part 'hr/sections/hr_dashboard_kpi_section.dart';
part 'hr/sections/hr_dashboard_metrics_section.dart';
part 'hr/sections/hr_dashboard_requests_section.dart';
part 'hr/sections/hr_dashboard_workflow_section.dart';
part 'dashboard_page_hr_data_part.dart';
part 'dashboard_page_hr_models_part.dart';
part 'dashboard_page_hr_cards_part.dart';
part 'dashboard_page_hr_actions_part.dart';
part 'dashboard_page_hr_workflow_part.dart';
part 'dashboard_page_hr_insight_panel_part.dart';
part 'dashboard_page_hr_helpers_part.dart';
part 'dashboard_page_hr_attendance_helpers_part.dart';
part 'dashboard_page_hr_document_helpers_part.dart';
part 'dashboard_page_shared_part.dart';
part 'manager/dashboard_manager.dart';
part 'manager/dashboard_manager_body.dart';
part 'manager/sections/manager_dashboard_charts_section.dart';
part 'manager/sections/manager_dashboard_due_soon_section.dart';
part 'manager/sections/manager_dashboard_header_section.dart';
part 'manager/sections/manager_dashboard_members_section.dart';
part 'manager/sections/manager_dashboard_overview_section.dart';
part 'manager/sections/manager_dashboard_performance_section.dart';
part 'manager/sections/manager_dashboard_stats_section.dart';
part 'dashboard_page_manager_assign_part.dart';
part 'dashboard_page_manager_task_type_helpers_part.dart';
part 'dashboard_page_manager_catalog_part.dart';
part 'dashboard_page_manager_templates_part.dart';
part 'dashboard_page_manager_weights_part.dart';
part 'dashboard_page_manager_load_part.dart';
part 'manager/helpers/manager_dashboard_member_metrics_part.dart';
part 'manager/helpers/manager_dashboard_execution_score_part.dart';
part 'dashboard_page_manager_aggregates_part.dart';
part 'dashboard_page_manager_monthly_part.dart';
part 'dashboard_page_manager_timeline_helpers_part.dart';
part 'dashboard_page_manager_timeline_dialog_part.dart';
part 'dashboard_page_manager_timeline_data_part.dart';
part 'dashboard_page_manager_qa_dialog_part.dart';
part 'dashboard_page_manager_review_dialog_ui_part.dart';
part 'dashboard_page_manager_review_dialog_submit_part.dart';
part 'dashboard_page_manager_review_dialog_content_part.dart';
part 'dashboard_page_manager_review_sections_part.dart';
part 'dashboard_page_manager_pending_review_part.dart';
part 'dashboard_page_manager_assign_widgets_part.dart';
part 'dashboard_page_manager_simple_list_part.dart';
part 'dashboard_page_manager_attachment_wrap_part.dart';
part 'employee/dashboard_employee.dart';
part 'employee/dashboard_employee_body.dart';
part 'employee/sections/employee_dashboard_action_center_section.dart';
part 'employee/sections/employee_dashboard_notifications_section.dart';
part 'employee/sections/employee_dashboard_recent_tasks_section.dart';
part 'employee/sections/employee_dashboard_summary_section.dart';
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
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        return _DashboardViewBody(state: state);
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
