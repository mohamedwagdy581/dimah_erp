import 'package:flutter/material.dart';

class TaskCardHeader extends StatelessWidget {
  const TaskCardHeader({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 6),
        if (description.trim().isNotEmpty) Text(description),
      ],
    );
  }
}
