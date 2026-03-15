part of 'dashboard_page.dart';

extension _ManagerDashboardTemplateHelpers on _ManagerDashboardState {
  List<_TaskTemplate> _taskTemplatesForDepartments(
    AppLocalizations t,
    List<String> departmentNames,
  ) {
    final templates = <_TaskTemplate>[];
    for (final rawName in departmentNames) {
      final name = rawName.toLowerCase();
      if (name.contains('it') ||
          name.contains('tech') ||
          name.contains('develop') ||
          name.contains('برمج') ||
          name.contains('تقني') ||
          name.contains('التطوير')) {
        templates.addAll([
          _TaskTemplate(
            id: 'it_login_signup',
            title: t.templateLoginSignup,
            description: t.templateLoginSignupDesc,
            taskType: 'development',
            priority: 'high',
            estimateHours: 16,
          ),
          _TaskTemplate(
            id: 'it_bugfix_release',
            title: t.templateBugFixRelease,
            description: t.templateBugFixReleaseDesc,
            taskType: 'bug_fix',
            priority: 'high',
            estimateHours: 8,
          ),
          _TaskTemplate(
            id: 'it_regression_testing',
            title: t.templateRegressionTesting,
            description: t.templateRegressionTestingDesc,
            taskType: 'testing',
            priority: 'medium',
            estimateHours: 6,
          ),
        ]);
        continue;
      }
      if (name.contains('fin') ||
          name.contains('account') ||
          name.contains('مال') ||
          name.contains('محاسب')) {
        templates.addAll([
          _TaskTemplate(
            id: 'finance_transfer_batch',
            title: t.templateTransferBatch,
            description: t.templateTransferBatchDesc,
            taskType: 'transfer',
            priority: 'medium',
            estimateHours: 4,
          ),
          _TaskTemplate(
            id: 'finance_monthly_report',
            title: t.templateMonthlyFinanceReport,
            description: t.templateMonthlyFinanceReportDesc,
            taskType: 'report',
            priority: 'high',
            estimateHours: 10,
          ),
          _TaskTemplate(
            id: 'finance_tax_submission',
            title: t.templateTaxSubmission,
            description: t.templateTaxSubmissionDesc,
            taskType: 'tax',
            priority: 'high',
            estimateHours: 12,
          ),
        ]);
        continue;
      }
      if (name.contains('hr') ||
          name.contains('human') ||
          name.contains('بشر') ||
          name.contains('موارد')) {
        templates.addAll([
          _TaskTemplate(
            id: 'hr_onboarding_pack',
            title: t.templateOnboardingPack,
            description: t.templateOnboardingPackDesc,
            taskType: 'onboarding',
            priority: 'medium',
            estimateHours: 5,
          ),
          _TaskTemplate(
            id: 'hr_document_audit',
            title: t.templateDocumentAudit,
            description: t.templateDocumentAuditDesc,
            taskType: 'employee_docs',
            priority: 'medium',
            estimateHours: 6,
          ),
          _TaskTemplate(
            id: 'hr_recruitment_followup',
            title: t.templateRecruitmentFollowup,
            description: t.templateRecruitmentFollowupDesc,
            taskType: 'recruitment',
            priority: 'high',
            estimateHours: 8,
          ),
        ]);
        continue;
      }
    }
    if (templates.isEmpty) {
      templates.add(
        _TaskTemplate(
          id: 'general_followup',
          title: t.templateGeneralFollowup,
          description: t.templateGeneralFollowupDesc,
          taskType: 'general',
          priority: 'medium',
          estimateHours: 4,
        ),
      );
    }
    return templates;
  }
}
