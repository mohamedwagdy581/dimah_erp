import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/approval_request.dart';
import '../cubit/approvals_cubit.dart';
import '../cubit/approvals_state.dart';
import '../widgets/approvals_pagination_bar.dart';
import '../widgets/approvals_table.dart';

class ApprovalsTableSection extends StatelessWidget {
  const ApprovalsTableSection({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApprovalsCubit, ApprovalsState>(
      builder: (context, state) {
        final cubit = context.read<ApprovalsCubit>();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(cubit: cubit, state: state, readOnly: readOnly),
              const SizedBox(height: 12),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: ApprovalsTable(
                  items: state.items,
                  onApprove: readOnly ? null : cubit.approve,
                  onReject: readOnly
                      ? null
                      : (id) => _reject(context, id, cubit),
                  showActions: !readOnly,
                  onViewDetails: (req) => _showDetails(context, req),
                ),
              ),
              const SizedBox(height: 12),
              ApprovalsPaginationBar(
                page: state.page,
                totalPages: state.totalPages,
                total: state.total,
                canPrev: state.canPrev,
                canNext: state.canNext,
                onPrev: cubit.prevPage,
                onNext: cubit.nextPage,
                pageSize: state.pageSize,
                onPageSizeChanged: cubit.setPageSize,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _reject(
    BuildContext context,
    String id,
    ApprovalsCubit cubit,
  ) async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.rejectRequest),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: t.reasonOptional,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t.reject),
          ),
        ],
      ),
    );
    if (ok == true) {
      await cubit.reject(id, reason: controller.text.trim());
    }
  }

  void _showDetails(BuildContext context, ApprovalRequest req) {
    final t = AppLocalizations.of(context)!;
    final payload = req.payload ?? {};
    final notes = payload['notes']?.toString();
    final fileUrl = payload['file_url']?.toString();
    final reason = req.rejectReason ?? payload['reason']?.toString() ?? '-';
    final leaveId = payload['leave_id']?.toString();

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.requestDetails),
        content: FutureBuilder<Map<String, String?>>(
          future: _loadLeaveExtras(leaveId),
          builder: (context, snap) {
            final extraNotes = snap.data?['notes'];
            final extraFile = snap.data?['file_url'];
            final resolvedNotes = notes ?? extraNotes ?? '-';
            final resolvedFile = fileUrl ?? extraFile ?? '';

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${t.type}: ${req.requestType}'),
                const SizedBox(height: 6),
                Text('${t.status}: ${req.status}'),
                const SizedBox(height: 6),
                Text('${t.notes}: $resolvedNotes'),
                const SizedBox(height: 6),
                if (reason != '-') Text('${t.reason}: $reason'),
                const SizedBox(height: 6),
                if (resolvedFile.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText('${t.file}: $resolvedFile'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _openAttachment(context, resolvedFile),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: Text(t.openAttachment),
                      ),
                    ],
                  )
                else
                  Text('${t.file}: -'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              final nav = Navigator.of(context, rootNavigator: true);
              if (nav.canPop()) nav.pop();
            },
            child: Text(t.close),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String?>> _loadLeaveExtras(String? leaveId) async {
    if (leaveId == null || leaveId.isEmpty) return const {};
    final client = Supabase.instance.client;
    final data = await client
        .from('leave_requests')
        .select('notes, file_url')
        .eq('id', leaveId)
        .maybeSingle();
    if (data == null) return const {};
    return {
      'notes': data['notes']?.toString(),
      'file_url': data['file_url']?.toString(),
    };
  }

  Future<void> _openAttachment(BuildContext context, String url) async {
    final t = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.invalidAttachmentUrl)));
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.unableOpenAttachment)));
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.cubit,
    required this.state,
    required this.readOnly,
  });

  final ApprovalsCubit cubit;
  final ApprovalsState state;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.menuApprovals,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String?>(
              value: state.status,
              onChanged: (v) => cubit.statusFilterChanged(v),
              items: [
                DropdownMenuItem(value: null, child: Text(t.all)),
                DropdownMenuItem(
                  value: 'pending_assigned',
                  child: Text(t.assignedToMe),
                ),
                DropdownMenuItem(value: 'pending', child: Text(t.statusPending)),
                DropdownMenuItem(value: 'approved', child: Text(t.statusApproved)),
                DropdownMenuItem(value: 'rejected', child: Text(t.statusRejected)),
              ],
            ),
            DropdownButton<String?>(
              value: state.requestType,
              onChanged: (v) => cubit.typeFilterChanged(v),
              items: [
                DropdownMenuItem(value: null, child: Text(t.allTypes)),
                DropdownMenuItem(value: 'leave', child: Text(t.leave)),
                DropdownMenuItem(
                  value: 'attendance_correction',
                  child: Text(t.menuAttendance),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () => cubit.toggleSort('created_at'),
              icon: const Icon(Icons.schedule),
              label: Text(
                state.sortBy == 'created_at'
                    ? (state.ascending ? t.createdAsc : t.createdDesc)
                    : t.sortCreated,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
