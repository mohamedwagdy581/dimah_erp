import 'package:erp_sys/core/ui/app_data_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/ui/employee_theme.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/employee_profile_details.dart';
import '../services/employee_profile_report_service.dart';
import '../widgets/employee_profile/add_compensation_version_dialog.dart';
import '../widgets/employee_profile/add_contract_version_dialog.dart';
import '../widgets/employee_profile/add_employee_settlement_dialog.dart';
import '../widgets/employee_profile/employee_profile_edit_dialog.dart';
import '../widgets/employee_profile/employee_profile_error_view.dart';
import '../widgets/employee_profile/employee_profile_identity_header.dart';
import '../widgets/employee_profile/employee_profile_sections.dart';
import '../widgets/employee_attendance_identity_dialog.dart';
import '../widgets/employee_profile/employee_login_dialog.dart';
import '../../domain/models/employee_login_result.dart';
import '../../data/repos/employee_status_repo.dart';
import '../widgets/employee_status_dialog.dart';
import '../widgets/employee_job_level_panel.dart';

class EmployeeProfilePage extends StatefulWidget {
  const EmployeeProfilePage({
    super.key,
    required this.employeeId,
    this.autoOpenAddContract = false,
    this.initialContractStartDate,
    this.initialContractEndDate,
    this.initialOldContractEndDate,
  });

  final String employeeId;
  final bool autoOpenAddContract;
  final DateTime? initialContractStartDate;
  final DateTime? initialContractEndDate;
  final DateTime? initialOldContractEndDate;

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  late Future<EmployeeProfileDetails> _future;
  bool _didAutoOpenContract = false;
  int _section = 2;

  @override
  void initState() {
    super.initState();
    _future = _loadProfile();
  }

  Future<EmployeeProfileDetails> _loadProfile() {
    return AppDI.employeesRepo.fetchEmployeeProfile(
      employeeId: widget.employeeId,
    );
  }

  Future<void> _reload() async {
    if (!mounted) return;
    final nextProfile = _loadProfile();
    setState(() {
      _future = nextProfile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final session = context.read<SessionCubit>().state;
    final role = session is SessionReady ? session.user.role : '';
    final canEdit = role == 'admin' || role == 'hr';

    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final tabs = [
      ar ? 'البيانات الشخصية' : 'Personal details',
      ar ? 'الوظيفة' : 'Employment',
      ar ? 'العقود' : 'Contracts',
      ar ? 'التعويضات' : 'Compensation',
      t.documents,
      ar ? 'الإجازات' : 'Leave',
      ar ? 'المخالصات' : 'Settlements',
    ];
    return Theme(
      data: EmployeeTheme.from(Theme.of(context)),
      child: Scaffold(
        appBar: ['hr', 'admin'].contains(role)
            ? null
            : AppBar(title: Text(t.employeeProfileTitle)),
        body: FutureBuilder<EmployeeProfileDetails>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingState();
            }
            if (snapshot.hasError) {
              return EmployeeProfileErrorView(
                error: snapshot.error,
                onRetry: _reload,
              );
            }

            final profile = snapshot.data!;
            if (widget.autoOpenAddContract && !_didAutoOpenContract) {
              _didAutoOpenContract = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _openDialog(
                  AddContractVersionDialog(
                    profile: profile,
                    initialStartDate: widget.initialContractStartDate,
                    initialEndDate: widget.initialContractEndDate,
                    initialOldEndDate: widget.initialOldContractEndDate,
                  ),
                );
              });
            }
            return Container(
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: EmployeeProfileIdentityHeader(
                      onBack: () => context.go('/employees'),
                      profile: profile,
                      canEdit: canEdit,
                      onStatus: canEdit
                          ? () async {
                              final changed = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => EmployeeStatusDialog(
                                  name: profile.fullName,
                                  inactive: profile.status == 'inactive',
                                  save: () => EmployeeStatusRepo(AppDI.supabase)
                                      .setStatus(
                                        profile.id,
                                        profile.status == 'inactive'
                                            ? 'active'
                                            : 'inactive',
                                      ),
                                ),
                              );
                              if (mounted && changed == true) await _reload();
                            }
                          : null,
                      onDownload: () =>
                          EmployeeProfileReportService.showDownloadOptions(
                            context,
                            profile,
                          ),
                      onEdit: canEdit
                          ? () => _openDialog(
                              EmployeeProfileEditDialog(profile: profile),
                            )
                          : null,
                      onLogin: canEdit && profile.status != 'inactive'
                          ? () async {
                              final result =
                                  await showDialog<EmployeeLoginResult>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => EmployeeLoginDialog(
                                      repo: AppDI.employeesRepo,
                                      employeeId: profile.id,
                                      email: profile.email,
                                    ),
                                  );
                              if (!context.mounted || result == null) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ar
                                        ? 'تم تجهيز حساب ${result.email}. ${result.accountCreated ? 'يمكنه الدخول بكلمة المرور التي حددتها.' : 'الحساب يحتفظ بكلمة مروره الحالية.'}'
                                        : 'Login ready for ${result.email}. ${result.accountCreated ? 'Use the password you entered.' : 'Existing password unchanged.'}',
                                  ),
                                ),
                              );
                            }
                          : null,
                      onIdentity: canEdit
                          ? () => _openDialog(
                              EmployeeAttendanceIdentityDialog(
                                employeeId: profile.id,
                                repo: AppDI.attendanceIdentityRepo,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  EmployeeJobLevelPanel(
                    employeeId: profile.id,
                    canEdit: canEdit,
                  ),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFECE7F5)),
                        bottom: BorderSide(color: Color(0xFFECE7F5)),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, box) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: box.maxWidth < 840 ? 840 : box.maxWidth,
                          child: Row(
                            children: [
                              for (var i = 0; i < tabs.length; i++)
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: _section == i
                                              ? const Color(0xFF8659BB)
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: TextButton(
                                      onPressed: () =>
                                          setState(() => _section = i),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 14,
                                        ),
                                        foregroundColor: _section == i
                                            ? const Color(0xFF8659BB)
                                            : const Color(0xFF66638B),
                                      ),
                                      child: Text(
                                        tabs[i],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: _section == i
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  EmployeeProfileSections(
                    section: _section,
                    profile: profile,
                    canEdit: canEdit,
                    onAddCompensationVersion: () => _openDialog(
                      AddCompensationVersionDialog(profile: profile),
                    ),
                    onAddContractVersion: () =>
                        _openDialog(AddContractVersionDialog(profile: profile)),
                    onAddSettlement: () => _openDialog(
                      AddEmployeeSettlementDialog(profile: profile),
                    ),
                    onOpenUrl: _openUrl,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openDialog(Widget dialog) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => dialog);
    if (ok == true && mounted) await _reload();
  }

  Future<void> _openUrl(String value) async {
    final t = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(value);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.invalidUrl)));
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.unableOpenFile)));
    }
  }
}
