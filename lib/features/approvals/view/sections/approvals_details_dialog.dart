import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/approval_request.dart';

void showApprovalDetailsDialog(BuildContext context, ApprovalRequest req) {
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
                    Expanded(child: SelectableText('${t.file}: $resolvedFile')),
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
            if (nav.canPop()) {
              nav.pop();
            }
          },
          child: Text(t.close),
        ),
      ],
    ),
  );
}

Future<Map<String, String?>> _loadLeaveExtras(String? leaveId) async {
  if (leaveId == null || leaveId.isEmpty) {
    return const {};
  }
  final client = Supabase.instance.client;
  final data = await client
      .from('leave_requests')
      .select('notes, file_url')
      .eq('id', leaveId)
      .maybeSingle();
  if (data == null) {
    return const {};
  }
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
