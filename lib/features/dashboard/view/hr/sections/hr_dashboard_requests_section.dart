part of '../../dashboard_page.dart';

class _HrRequestsSection extends StatelessWidget {
  const _HrRequestsSection({
    required this.data,
    required this.isWide,
    required this.maxWidth,
    required this.dateOnly,
  });

  final _HrDashboardData data;
  final bool isWide;
  final double maxWidth;
  final String Function(DateTime value) dateOnly;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final width = isWide ? (maxWidth - 24) / 2 : maxWidth;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _InsightPanel(
          width: width,
          title: t.pendingRequestsTop10,
          count: data.pendingItems.length,
          emptyText: t.noPendingRequests,
          children: data.pendingItems
              .map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.pending_actions),
                  title: Text(item.employeeName),
                  subtitle: Text(
                    '${item.requestType} | ${dateOnly(item.createdAt)}',
                  ),
                ),
              )
              .toList(),
        ),
        _InsightPanel(
          width: width,
          title: t.expiringDocuments30Days,
          count: data.expiringDocuments.length,
          emptyText: t.noDocumentExpiries30Days,
          children: data.expiringDocuments
              .map(
                (doc) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(doc['employee_name']?.toString() ?? '-'),
                  subtitle: Text(
                    '${doc['doc_type'] ?? t.documentLabel} | '
                    '${t.expires}: ${doc['expires_at'] ?? '-'}',
                  ),
                ),
              )
              .toList(),
        ),
        _InsightPanel(
          width: width,
          title: t.expiringDocumentsByType,
          count: data.expiringDocumentTypeCounts.length,
          emptyText: t.noDocumentExpiries30Days,
          children: data.expiringDocumentTypeCounts.entries
              .map(
                (entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.label_outline),
                  title: Text(_labelForDocumentType(t, entry.key)),
                  trailing: Text(
                    '${entry.value}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
