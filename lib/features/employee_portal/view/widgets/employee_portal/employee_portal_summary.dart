import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../data/repos/employee_portal_summary_repo.dart';
import 'portal_badge.dart';

class EmployeePortalSummary extends StatefulWidget {
  const EmployeePortalSummary({super.key, required this.employeeId});

  final String employeeId;

  @override
  State<EmployeePortalSummary> createState() => _EmployeePortalSummaryState();
}

class _EmployeePortalSummaryState extends State<EmployeePortalSummary> {
  late final EmployeePortalSummaryRepo _repo;
  late Future<Map<String, int>> _future;

  @override
  void initState() {
    super.initState();
    _repo = EmployeePortalSummaryRepo(Supabase.instance.client);
    _future = _repo.load(widget.employeeId);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, int>>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const {};
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PortalBadge(label: t.allTasks, value: data['all'] ?? 0),
              PortalBadge(label: t.statusInProgress, value: data['in_progress'] ?? 0),
              PortalBadge(label: t.reviewPending, value: data['review_pending'] ?? 0),
              PortalBadge(label: t.qaPending, value: data['qa_pending'] ?? 0),
            ],
          ),
        );
      },
    );
  }
}
