import 'package:flutter/material.dart';
import '../../../../core/ui/app_data_state.dart';
import '../../data/hr_form_drafts_repo.dart';
import '../../domain/models/hr_form_template_def.dart';
import '../../domain/models/hr_form_submission.dart';

class HrDraftHistoryDialog extends StatefulWidget {
  const HrDraftHistoryDialog({super.key, required this.repo});
  final HrFormDraftsRepo repo;
  @override
  State<HrDraftHistoryDialog> createState() => _HrDraftHistoryDialogState();
}

class _HrDraftHistoryDialogState extends State<HrDraftHistoryDialog> {
  late Future<List<HrSavedDraft>> future;
  final events = <String, Future<List<Map<String, dynamic>>>>{};
  String query = '';
  String status = 'all';
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String a, String e) => ar ? a : e;
  @override
  void initState() {
    super.initState();
    future = widget.repo.list();
  }

  void reload() {
    setState(() {
      future = widget.repo.list();
      events.clear();
    });
  }

  String date(DateTime d) =>
      d.toLocal().toIso8601String().substring(0, 16).replaceFirst('T', '  ');
  @override
  Widget build(BuildContext context) => Dialog(
    child: SizedBox(
      width: 800,
      height: MediaQuery.sizeOf(context).height * .8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr('المسودات وسجل الطلبات', 'Drafts and request history'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF21194E),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: reload,
                  tooltip: tr('تحديث', 'Refresh'),
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: tr('إغلاق', 'Close'),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              tr(
                'المسودات والطلبات الخاصة بحسابك. افتح الطلب لعرض حالته وسجل المراجعة.',
                'Your account’s drafts and requests. Open a request to see its status and review history.',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('draft-history-search'),
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                labelText: tr(
                  'بحث بالموظف أو النموذج',
                  'Search employee or form',
                ),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: InputDecoration(
                labelText: tr('الحالة', 'Status'),
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final s in [
                  'all',
                  'draft',
                  'pending',
                  'approved',
                  'rejected',
                ])
                  DropdownMenuItem(
                    value: s,
                    child: Text(
                      s == 'all'
                          ? tr('كل الحالات', 'All statuses')
                          : hrFormStatusLabel(s, ar),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => status = v ?? 'all'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<HrSavedDraft>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return AppFailureState(
                      error: snapshot.error,
                      onRetry: reload,
                    );
                  }
                  if (!snapshot.hasData) return const AppLoadingState();
                  final rows = snapshot.data!.where((d) {
                    final t = findHrFormTemplate(d.templateId);
                    return (status == 'all' || d.status == status) &&
                        '${t?.titleAr} ${t?.titleEn} ${d.employeeName ?? ''} ${d.id} ${d.reference ?? ''}'
                            .toLowerCase()
                            .contains(query.trim().toLowerCase());
                  }).toList();
                  if (rows.isEmpty) {
                    return Center(
                      child: Text(
                        tr('لا توجد مسودات مطابقة', 'No matching drafts'),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final d = rows[index];
                      final t = findHrFormTemplate(d.templateId);
                      return Card(
                        child: ExpansionTile(
                          key: ValueKey('draft-${d.id}'),
                          title: Text(t?.title(ar) ?? d.templateId),
                          subtitle: Text(
                            '${d.employeeName ?? tr('بدون موظف', 'No employee')}\n${date(d.updatedAt)} · ${hrFormStatusLabel(d.status, ar)} · v${d.version}\n${d.reference ?? ''} ${hrFormApproverLabel(d.approverRole, ar)}${d.rejectReason == null ? '' : '\n${d.rejectReason}'}',
                          ),
                          trailing: OutlinedButton.icon(
                            key: ValueKey('resume-${d.id}'),
                            onPressed: t == null
                                ? null
                                : () => Navigator.pop(context, d),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(
                              d.status == 'draft'
                                  ? tr('استكمال', 'Resume')
                                  : tr('عرض', 'View'),
                            ),
                          ),
                          onExpansionChanged: (open) {
                            if (open && !events.containsKey(d.id)) {
                              setState(() {
                                events[d.id] = widget.repo.events(d.id);
                              });
                            }
                          },
                          children: [
                            if (events[d.id] != null)
                              FutureBuilder<List<Map<String, dynamic>>>(
                                future: events[d.id],
                                builder: (context, s) {
                                  if (s.hasError) {
                                    return AppFailureState(
                                      error: s.error,
                                      onRetry: () {
                                        setState(() {
                                          events[d.id] = widget.repo.events(
                                            d.id,
                                          );
                                        });
                                      },
                                      compact: true,
                                    );
                                  }
                                  if (!s.hasData) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  return Column(
                                    children: [
                                      for (final e in s.data!)
                                        ListTile(
                                          dense: true,
                                          leading: const Icon(Icons.history),
                                          title: Text(
                                            hrFormEventLabel(
                                              e['action'].toString(),
                                              ar,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${date(DateTime.parse(e['created_at'] as String))} · v${e['version']} ${hrFormApproverLabel(e['actor_role'] as String?, ar)}${e['note'] == null ? '' : '\n${e['note']}'}',
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
