import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/app_di.dart';
import '../../../leaves/view/cubit/leaves_cubit.dart';
import '../../../leaves/view/sections/leaves_resubmit_dialog.dart';
import '../cubit/employee_request_history_cubit.dart';
import '../widgets/employee_requests/employee_request_history_view.dart';
import '../widgets/employee_requests/request_history_labels.dart';
import '../../data/repos/employee_leave_attachment.dart';
import '../cubit/employee_leave_request_cubit.dart';
import '../widgets/employee_requests/employee_leave_request_view.dart';

class EmployeeRequestsSection extends StatefulWidget {
  const EmployeeRequestsSection({super.key, required this.employeeId});
  final String employeeId;
  @override
  State<EmployeeRequestsSection> createState() =>
      _EmployeeRequestsSectionState();
}

class _EmployeeRequestsSectionState extends State<EmployeeRequestsSection> {
  bool _history = false;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => EmployeeLeaveRequestCubit(
      AppDI.leavesRepo,
      employeeId: widget.employeeId,
      uploadAttachment: uploadEmployeeLeaveAttachment,
    )..loadBalance(),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: _history,
          child: ExcludeFocus(
            excluding: _history,
            child: EmployeeLeaveRequestView(
              showBalanceSummary: true,
              onHistory: () => setState(() => _history = true),
            ),
          ),
        ),
        if (_history)
          Positioned.fill(
            child: BlocProvider(
              create: (_) => EmployeeRequestHistoryCubit(
                AppDI.approvalsRepo,
                employeeId: widget.employeeId,
              )..load(),
              child: BlocProvider(
                create: (_) => LeavesCubit(
                  AppDI.leavesRepo,
                  employeeId: widget.employeeId,
                ),
                child: Builder(
                  builder: (historyContext) => EmployeeRequestHistoryView(
                    showBalanceSummary: true,
                    onLeave: () => setState(() => _history = false),
                    onAttendance: () => context.go('/my?tab=attendance'),
                    onResubmit: (request) async {
                      final leave = historyResubmittableLeave(request);
                      if (leave == null ||
                          leave.employeeId != widget.employeeId) {
                        return;
                      }
                      await openLeaveResubmitDialog(historyContext, leave);
                      if (!historyContext.mounted) return;
                      await historyContext
                          .read<EmployeeRequestHistoryCubit>()
                          .load();
                      if (!historyContext.mounted) return;
                      final balances = historyContext
                          .read<EmployeeLeaveRequestCubit>();
                      await balances.loadBalance(year: balances.balanceYear);
                    },
                    onAttachment: (url) async {
                      final uri = Uri.tryParse(url);
                      if (uri == null ||
                          (uri.scheme != 'https' && uri.scheme != 'http')) {
                        return;
                      }
                      try {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (_) {
                        if (historyContext.mounted) {
                          ScaffoldMessenger.of(historyContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                Localizations.localeOf(
                                          historyContext,
                                        ).languageCode ==
                                        'ar'
                                    ? 'تعذّر فتح المرفق'
                                    : 'Unable to open attachment',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
