import 'package:flutter/material.dart';
import 'profile_kv_row.dart';

class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFECE7F5)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF24204E),
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, box) {
                final columns = box.maxWidth >= 900
                    ? 3
                    : box.maxWidth >= 550
                    ? 2
                    : 1;
                final width = (box.maxWidth - 12 * (columns - 1)) / columns;
                final content = <Widget>[];
                var fields = <Widget>[];
                void flush() {
                  if (fields.isEmpty) return;
                  content.add(
                    Wrap(spacing: 12, runSpacing: 12, children: fields),
                  );
                  fields = <Widget>[];
                }

                for (final child in children) {
                  if (child is ProfileKvRow) {
                    fields.add(SizedBox(width: width, child: child));
                  } else {
                    flush();
                    content.add(child);
                  }
                }
                flush();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: content,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
