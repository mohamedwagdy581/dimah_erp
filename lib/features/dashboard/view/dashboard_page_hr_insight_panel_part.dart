part of 'dashboard_page.dart';

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({
    required this.width,
    required this.title,
    required this.count,
    required this.emptyText,
    required this.children,
  });

  final double width;
  final String title;
  final int count;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$count'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (children.isEmpty) Text(emptyText) else ...children,
            ],
          ),
        ),
      ),
    );
  }
}
