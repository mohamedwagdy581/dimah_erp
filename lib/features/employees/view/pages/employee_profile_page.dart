import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/employee_profile_details.dart';
import '../services/employee_profile_report_service.dart';
import '../widgets/employee_profile/add_compensation_version_dialog.dart';
import '../widgets/employee_profile/add_contract_version_dialog.dart';
import '../widgets/employee_profile/employee_profile_edit_dialog.dart';
import '../widgets/employee_profile/employee_profile_error_view.dart';
import '../widgets/employee_profile/employee_profile_header.dart';
import '../widgets/employee_profile/employee_profile_sections.dart';

class EmployeeProfilePage extends StatefulWidget {
  const EmployeeProfilePage({super.key, required this.employeeId});

  final String employeeId;

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  late Future<EmployeeProfileDetails> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadProfile();
  }

  Future<EmployeeProfileDetails> _loadProfile() {
    return AppDI.employeesRepo.fetchEmployeeProfile(employeeId: widget.employeeId);
  }

  Future<void> _reload() async {
    setState(() => _future = _loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final session = context.read<SessionCubit>().state;
    final role = session is SessionReady ? session.user.role : '';
    final canEdit = role == 'admin' || role == 'hr';

    return Scaffold(
      appBar: AppBar(title: Text(t.employeeProfileTitle)),
      body: FutureBuilder<EmployeeProfileDetails>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmployeeProfileErrorView(error: snapshot.error, onRetry: _reload);
          }

          final profile = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              EmployeeProfileHeader(
                profile: profile,
                canEdit: canEdit,
                onDownload: () => EmployeeProfileReportService.showDownloadOptions(context, profile),
                onEdit: canEdit ? () => _openDialog(EmployeeProfileEditDialog(profile: profile)) : null,
              ),
              const SizedBox(height: 12),
              EmployeeProfileSections(
                profile: profile,
                canEdit: canEdit,
                onAddCompensationVersion: () => _openDialog(AddCompensationVersionDialog(profile: profile)),
                onAddContractVersion: () => _openDialog(AddContractVersionDialog(profile: profile)),
                onOpenUrl: _openUrl,
              ),
            ],
          );
        },
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.invalidUrl)));
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.unableOpenFile)));
    }
  }
}
