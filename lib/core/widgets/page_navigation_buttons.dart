import 'package:flutter/material.dart';

/// Physical navigation: previous is always on the left, next on the right.
class PageNavigationButtons extends StatelessWidget {
  const PageNavigationButtons({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.previousTooltip,
    required this.nextTooltip,
    this.previousKey,
    this.nextKey,
    this.center,
  });
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String previousTooltip;
  final String nextTooltip;
  final Key? previousKey;
  final Key? nextKey;
  final Widget? center;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    textDirection: TextDirection.ltr,
    children: [
      IconButton(
        key: previousKey,
        tooltip: previousTooltip,
        onPressed: onPrevious,
        icon: const Icon(Icons.chevron_left, textDirection: TextDirection.ltr),
      ),
      if (center != null) Flexible(child: center!),
      IconButton(
        key: nextKey,
        tooltip: nextTooltip,
        onPressed: onNext,
        icon: const Icon(Icons.chevron_right, textDirection: TextDirection.ltr),
      ),
    ],
  );
}
