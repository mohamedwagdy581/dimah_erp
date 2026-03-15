part of 'dashboard_page.dart';

class _PerformanceListCard extends StatelessWidget {
  const _PerformanceListCard({
    required this.title,
    required this.emptyText,
    required this.members,
    required this.color,
  });

  final String title;
  final String emptyText;
  final List<_MemberProductivity> members;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (members.isEmpty)
                Text(emptyText)
              else
                ...members.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(m.name, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${m.productivityPercent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
