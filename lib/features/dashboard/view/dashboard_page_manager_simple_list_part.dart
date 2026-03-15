part of 'dashboard_page.dart';

class _ManagerSimpleListCard extends StatelessWidget {
  const _ManagerSimpleListCard({required this.title, required this.emptyText, required this.children});

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (children.isEmpty) Text(emptyText) else ...children,
          ],
        ),
      ),
    );
  }
}
