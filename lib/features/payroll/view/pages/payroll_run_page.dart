import 'package:erp_sys/core/ui/app_data_state.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/app_di.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/utils/safe_file_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/payroll_assignee_option.dart';
import '../../domain/models/payroll_item.dart';
import '../../domain/models/payroll_run.dart';
import '../../domain/payroll_approval_error.dart';
import '../cubit/payroll_run_cubit.dart';
import '../cubit/payroll_run_state.dart';
import '../widgets/payroll_run_design.dart';
import '../widgets/payroll_preparation_view.dart';
import '../widgets/finance_payroll_workspace.dart';
import '../widgets/finance_disbursement_workspace.dart';
import '../../data/repos/payroll_disbursement_repo.dart';

class PayrollRunPage extends StatelessWidget {
  const PayrollRunPage({super.key, required this.runId});

  final String runId;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    if (session is SessionReady &&
        session.user.role == 'finance_manager' &&
        GoRouterState.of(context).uri.queryParameters['disbursement'] == '1') {
      return FinanceDisbursementWorkspace(
        repo: SupabasePayrollDisbursementRepo(
          AppDI.payrollRepo,
          AppDI.supabase,
        ),
        runId: runId,
        onReview: () => context.go('/payroll/$runId'),
      );
    }
    if (session is SessionReady &&
        session.user.role == 'finance_manager' &&
        GoRouterState.of(context).uri.queryParameters['disbursement'] != '1') {
      return FinancePayrollWorkspace(
        repo: AppDI.payrollRepo,
        initialRunId: runId,
        onDisbursement: (id) => context.go('/payroll/$id?disbursement=1'),
        onHistory: () => context.go('/payroll?history=1'),
      );
    }
    return BlocProvider(
      create: (_) => PayrollRunCubit(AppDI.payrollRepo)..load(runId),
      child: _PayrollRunBody(runId: runId),
    );
  }
}

class _PayrollRunBody extends StatefulWidget {
  const _PayrollRunBody({required this.runId});

  final String runId;
  @override
  State<_PayrollRunBody> createState() => _PayrollRunBodyState();
}

class _PayrollRunBodyState extends State<_PayrollRunBody> {
  String get runId => widget.runId;
  bool _busy = false;
  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, sessionState) {
        if (sessionState is! SessionReady) return const SizedBox.shrink();
        final session = sessionState;
        final userRole = session.user.role;
        final currentEmployeeId = session.user.employeeId;

        return BlocBuilder<PayrollRunCubit, PayrollRunState>(
          builder: (context, state) {
            final run = state.run;

            if (state.loading && run == null) {
              return const AppLoadingState();
            }
            if (run == null) {
              if (state.error != null) {
                return AppFailureState(
                  error: state.error,
                  onRetry: () => context.read<PayrollRunCubit>().load(runId),
                );
              }
              return AppEmptyState(
                title: isArabic ? 'المسير غير موجود' : 'Payroll run not found',
              );
            }
            if (userRole == 'hr' &&
                (run.status == 'draft' || run.status.startsWith('rejected'))) {
              return PayrollPreparationView(
                key: ValueKey(run.id),
                repo: AppDI.payrollRepo,
                savedRun: run,
                onHistory: () => context.go('/payroll?history=1'),
                onSubmitted: (_) => context.read<PayrollRunCubit>().load(runId),
              );
            }
            return Column(
              children: [
                if (state.loading || _busy) const LinearProgressIndicator(),
                if (state.error != null)
                  AppFailureState(
                    error: state.error,
                    compact: true,
                    onRetry: () => context.read<PayrollRunCubit>().load(runId),
                  ),
                Expanded(
                  child: AbsorbPointer(
                    absorbing: state.loading || _busy,
                    child: PayrollRunDesign(
                      run: run,
                      items: state.items,
                      preparation:
                          userRole == 'hr' &&
                          (run.status == 'draft' ||
                              run.status.startsWith('rejected')),
                      actions: _buildHeader(
                        context,
                        t,
                        isArabic,
                        userRole,
                        currentEmployeeId,
                        state,
                        run,
                      ),
                      workflow: _PayrollWorkflowSummary(run: run),
                      onBack: () => context.go('/payroll'),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations t,
    bool isArabic,
    String role,
    String? currentEmployeeId,
    PayrollRunState state,
    PayrollRun? run,
  ) {
    final status = run?.status ?? 'draft';
    final disbursementStatus = run?.disbursementStatus ?? 'not_started';
    final isAssignedAccountant =
        role == 'accountant' &&
        currentEmployeeId != null &&
        currentEmployeeId.isNotEmpty &&
        currentEmployeeId == run?.disbursementAssigneeEmployeeId;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildStatusChip(
          _approvalStatusLabel(status, isArabic),
          _approvalStatusColor(status),
        ),
        if (status == 'approved')
          _buildStatusChip(
            _disbursementStatusLabel(disbursementStatus, isArabic),
            _disbursementStatusColor(disbursementStatus),
          ),
        if (role == 'hr' &&
            (status == 'draft' || status.startsWith('rejected')))
          ElevatedButton.icon(
            onPressed: () => _act(() => _submitToFinance(context)),
            icon: const Icon(Icons.send),
            label: Text(
              isArabic ? 'إرسال للمراجعة المالية' : 'Send to finance review',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B74BF),
              foregroundColor: Colors.white,
            ),
          ),
        if (role == 'finance_manager' &&
            status == 'pending_finance_manager') ...[
          ElevatedButton.icon(
            onPressed: () => _act(() => _financeApprove(context)),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              isArabic ? 'اعتماد وإرسال للأدمن' : 'Approve & Send to Admin',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B74BF),
              foregroundColor: Colors.white,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _act(() => _showRejectDialog(context)),
            icon: const Icon(Icons.cancel_outlined),
            label: Text(isArabic ? 'رفض' : 'Reject'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
        if (role == 'admin' && status == 'pending_admin_approval') ...[
          ElevatedButton.icon(
            onPressed: () => _act(() => _adminApprove(context)),
            icon: const Icon(Icons.verified_user_outlined),
            label: Text(isArabic ? 'اعتماد نهائي' : 'Final Approval'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B74BF),
              foregroundColor: Colors.white,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _act(() => _showRejectDialog(context)),
            icon: const Icon(Icons.cancel_outlined),
            label: Text(isArabic ? 'رفض' : 'Reject'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
        if (role == 'finance_manager' &&
            status == 'approved' &&
            (disbursementStatus == 'assigned_to_finance_manager' ||
                disbursementStatus == 'not_started'))
          ElevatedButton.icon(
            onPressed: () => _act(() => _assignToAccountant(context)),
            icon: const Icon(Icons.assignment_ind_outlined),
            label: Text(isArabic ? 'تحويل لمحاسب' : 'Assign to Accountant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B74BF),
              foregroundColor: Colors.white,
            ),
          ),
        if (isAssignedAccountant &&
            status == 'approved' &&
            disbursementStatus == 'assigned_to_accountant')
          ElevatedButton.icon(
            onPressed: () => _act(() => _markPaymentInProgress(context)),
            icon: const Icon(Icons.play_circle_outline),
            label: Text(isArabic ? 'بدء الصرف' : 'Start Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B74BF),
              foregroundColor: Colors.white,
            ),
          ),
        if (isAssignedAccountant &&
            status == 'approved' &&
            disbursementStatus == 'payment_in_progress')
          ElevatedButton.icon(
            onPressed: () => _act(() => _markPaid(context)),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(isArabic ? 'تم الصرف' : 'Mark as Paid'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B74BF),
              foregroundColor: Colors.white,
            ),
          ),
        ElevatedButton.icon(
          onPressed: state.items.isEmpty
              ? null
              : () => _exportCsvFile(context, state.items),
          icon: const Icon(Icons.download),
          label: Text(t.exportCsv),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: color,
    );
  }

  String _approvalStatusLabel(String status, bool isArabic) {
    switch (status) {
      case 'draft':
        return isArabic ? 'مسودة' : 'Draft';
      case 'pending_finance_manager':
        return isArabic ? 'بانتظار مدير المحاسبة' : 'Pending Finance Manager';
      case 'pending_admin_approval':
        return isArabic ? 'بانتظار الأدمن' : 'Pending Admin';
      case 'rejected_by_finance_manager':
        return isArabic
            ? 'مرفوض من مدير المحاسبة'
            : 'Rejected by Finance Manager';
      case 'rejected_by_admin':
        return isArabic ? 'مرفوض من الأدمن' : 'Rejected by Admin';
      case 'approved':
        return isArabic ? 'معتمد' : 'Approved';
      default:
        return status;
    }
  }

  String _disbursementStatusLabel(String status, bool isArabic) {
    switch (status) {
      case 'assigned_to_finance_manager':
        return isArabic ? 'مهمة عند مدير المحاسبة' : 'With Finance Manager';
      case 'assigned_to_accountant':
        return isArabic ? 'محول إلى محاسب' : 'Assigned to Accountant';
      case 'payment_in_progress':
        return isArabic ? 'الصرف قيد التنفيذ' : 'Payment in Progress';
      case 'paid':
        return isArabic ? 'تم الصرف' : 'Paid';
      default:
        return isArabic ? 'لم يبدأ' : 'Not Started';
    }
  }

  Color _approvalStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending_finance_manager':
      case 'pending_admin_approval':
        return Colors.orange;
      case 'rejected_by_finance_manager':
      case 'rejected_by_admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _disbursementStatusColor(String status) {
    switch (status) {
      case 'assigned_to_finance_manager':
        return Colors.deepPurple;
      case 'assigned_to_accountant':
        return Colors.blue;
      case 'payment_in_progress':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _submitToFinance(BuildContext context) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      await AppDI.payrollRepo.submitToFinanceManager(runId: runId);
      if (context.mounted) context.read<PayrollRunCubit>().load(runId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'لا يمكن إرسال مسير الرواتب لأن حساب الموارد البشرية الحالي غير مربوط بملف موظف.'
                : 'Cannot submit payroll because the current HR account is not linked to an employee profile.',
          ),
        ),
      );
    }
  }

  Future<void> _financeApprove(BuildContext context) async {
    try {
      await AppDI.payrollRepo.financeManagerApprove(runId: runId);
      if (context.mounted) context.read<PayrollRunCubit>().load(runId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _adminApprove(BuildContext context) async {
    try {
      await AppDI.payrollRepo.adminApprove(runId: runId);
      if (context.mounted) context.read<PayrollRunCubit>().load(runId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            payrollApprovalError(
              e,
              isArabic: Localizations.localeOf(context).languageCode == 'ar',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _assignToAccountant(BuildContext context) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final options = await AppDI.payrollRepo.fetchAssignableAccountants();
    if (!context.mounted) return;
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'لا يوجد محاسبون تابعون لمدير المحاسبة الحالي'
                : 'No accountants found under this finance manager',
          ),
        ),
      );
      return;
    }

    final selected = await showDialog<PayrollAssigneeOption>(
      context: context,
      builder: (ctx) => _AssignAccountantDialog(options: options),
    );
    if (selected == null) return;

    try {
      await AppDI.payrollRepo.assignDisbursementToAccountant(
        runId: runId,
        accountantEmployeeId: selected.employeeId,
      );
      if (context.mounted) {
        context.read<PayrollRunCubit>().load(runId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'تم تحويل مهمة الصرف إلى ${selected.fullName}'
                  : 'Disbursement task assigned to ${selected.fullName}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _markPaymentInProgress(BuildContext context) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      await AppDI.payrollRepo.markPaymentInProgress(runId: runId);
      if (context.mounted) {
        context.read<PayrollRunCubit>().load(runId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'تم بدء تنفيذ صرف الرواتب' : 'Payroll payment started',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _markPaid(BuildContext context) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    try {
      await AppDI.payrollRepo.markPaid(runId: runId);
      if (context.mounted) {
        context.read<PayrollRunCubit>().load(runId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'تم تعليم مسير الرواتب كمصروف'
                  : 'Payroll marked as paid',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'رفض مسير الرواتب' : 'Reject Payroll Run'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: isArabic
                ? 'اكتب سبب الرفض'
                : 'Enter reason for rejection',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isArabic ? 'رفض' : 'Reject'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (result != null && result.trim().isNotEmpty && context.mounted) {
      final role =
          (context.read<SessionCubit>().state as SessionReady).user.role;
      await AppDI.payrollRepo.rejectRun(
        runId: runId,
        reason: result.trim(),
        rejectedByRole: role,
      );
      if (context.mounted) context.read<PayrollRunCubit>().load(runId);
    }
  }

  Future<void> _exportCsvFile(
    BuildContext context,
    List<PayrollItem> items,
  ) async {
    final t = AppLocalizations.of(context)!;
    final buffer = StringBuffer();
    buffer.writeln(
      '${t.employee},${t.basic},${t.housing},${t.transport},${t.other},${t.total}',
    );
    for (final r in items) {
      buffer.writeln(
        '${_csv(r.employeeName)},${r.basicSalary},${r.housingAllowance},${r.transportAllowance},${r.otherAllowance},${r.total}',
      );
    }
    final fileName = 'payroll_${DateTime.now().millisecondsSinceEpoch}.csv';
    try {
      final saveLocation = await SafeFilePicker.saveLocation(
        context: context,
        suggestedName: fileName,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'CSV', extensions: ['csv']),
        ],
      );
      if (saveLocation == null) return;
      final data = Uint8List.fromList(
        utf8.encode('\ufeff${buffer.toString()}'),
      );
      final file = XFile.fromData(data, name: fileName, mimeType: 'text/csv');
      await file.saveTo(saveLocation.path);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.csvSavedTo(saveLocation.path))));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.exportFailed(e.toString()))));
    }
  }

  String _csv(String v) => '"${v.replaceAll('"', '""')}"';
}

class _PayrollWorkflowSummary extends StatelessWidget {
  const _PayrollWorkflowSummary({required this.run});

  final PayrollRun run;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _InfoLine(
              label: isArabic ? 'حالة الاعتماد' : 'Approval Status',
              value: _approvalStatusText(run.status, isArabic),
            ),
            _InfoLine(
              label: isArabic ? 'حالة الصرف' : 'Disbursement Status',
              value: _disbursementStatusText(
                run.disbursementStatus ?? 'not_started',
                isArabic,
              ),
            ),
            _InfoLine(
              label: isArabic ? 'المهمة المرتبطة' : 'Linked Task',
              value:
                  run.disbursementTaskId == null ||
                      run.disbursementTaskId!.isEmpty
                  ? (isArabic ? 'لم تُنشأ بعد' : 'Not created yet')
                  : _shortId(run.disbursementTaskId!),
            ),
            if ((run.disbursementAssigneeEmployeeId ?? '').isNotEmpty)
              _AssigneeInfoLine(
                employeeId: run.disbursementAssigneeEmployeeId!,
              ),
          ],
        ),
      ),
    );
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  String _approvalStatusText(String status, bool isArabic) {
    switch (status) {
      case 'draft':
        return isArabic ? 'مسودة' : 'Draft';
      case 'pending_finance_manager':
        return isArabic ? 'بانتظار مدير المحاسبة' : 'Pending Finance Manager';
      case 'pending_admin_approval':
        return isArabic ? 'بانتظار الأدمن' : 'Pending Admin';
      case 'rejected_by_finance_manager':
        return isArabic
            ? 'مرفوض من مدير المحاسبة'
            : 'Rejected by Finance Manager';
      case 'rejected_by_admin':
        return isArabic ? 'مرفوض من الأدمن' : 'Rejected by Admin';
      case 'approved':
        return isArabic ? 'معتمد نهائيًا' : 'Finally Approved';
      default:
        return status;
    }
  }

  String _disbursementStatusText(String status, bool isArabic) {
    switch (status) {
      case 'assigned_to_finance_manager':
        return isArabic ? 'عند مدير المحاسبة' : 'With Finance Manager';
      case 'assigned_to_accountant':
        return isArabic ? 'عند المحاسب المكلف' : 'With Assigned Accountant';
      case 'payment_in_progress':
        return isArabic ? 'الصرف قيد التنفيذ' : 'Payment in Progress';
      case 'paid':
        return isArabic ? 'تم الصرف' : 'Paid';
      default:
        return isArabic ? 'لم يبدأ بعد' : 'Not Started Yet';
    }
  }
}

class _AssigneeInfoLine extends StatefulWidget {
  const _AssigneeInfoLine({required this.employeeId});

  final String employeeId;

  @override
  State<_AssigneeInfoLine> createState() => _AssigneeInfoLineState();
}

class _AssigneeInfoLineState extends State<_AssigneeInfoLine> {
  late final Future<String> _futureName = _loadName();

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return FutureBuilder<String>(
      future: _futureName,
      builder: (context, snapshot) {
        final value =
            snapshot.data ??
            (snapshot.connectionState == ConnectionState.waiting
                ? (isArabic ? 'جارٍ التحميل...' : 'Loading...')
                : widget.employeeId);
        return _InfoLine(
          label: isArabic ? 'المكلف الحالي' : 'Current Assignee',
          value: value,
        );
      },
    );
  }

  Future<String> _loadName() async {
    final row = await Supabase.instance.client
        .from('employees')
        .select('full_name')
        .eq('id', widget.employeeId)
        .single();
    return (row['full_name'] ?? widget.employeeId).toString();
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AssignAccountantDialog extends StatefulWidget {
  const _AssignAccountantDialog({required this.options});

  final List<PayrollAssigneeOption> options;

  @override
  State<_AssignAccountantDialog> createState() =>
      _AssignAccountantDialogState();
}

class _AssignAccountantDialogState extends State<_AssignAccountantDialog> {
  String? _selectedEmployeeId;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return AlertDialog(
      title: Text(isArabic ? 'تحويل مهمة الصرف' : 'Assign Disbursement Task'),
      content: SizedBox(
        width: 380,
        child: DropdownButtonFormField<String>(
          initialValue: _selectedEmployeeId,
          decoration: InputDecoration(
            labelText: isArabic ? 'المحاسب' : 'Accountant',
            border: const OutlineInputBorder(),
          ),
          items: widget.options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.employeeId,
                  child: Text(option.fullName),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedEmployeeId = value;
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _selectedEmployeeId == null
              ? null
              : () {
                  final selected = widget.options.firstWhere(
                    (option) => option.employeeId == _selectedEmployeeId,
                  );
                  Navigator.of(context).pop(selected);
                },
          child: Text(isArabic ? 'تحويل' : 'Assign'),
        ),
      ],
    );
  }
}
