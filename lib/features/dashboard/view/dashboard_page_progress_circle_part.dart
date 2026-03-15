part of 'dashboard_page.dart';

class _ProductivityCircle extends StatelessWidget {
  const _ProductivityCircle({required this.value, required this.title});

  final double value;
  final String title;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 100).toDouble();
    final doneColor = v < 50
        ? const Color(0xFFFF4D4F)
        : v < 80
            ? const Color(0xFFFFC53D)
            : const Color(0xFF22C55E);
    final remainingColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18);
    final surface = Theme.of(context).colorScheme.surface;

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: v / 100),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, progress, _) => SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        doneColor.withValues(alpha: 0.18),
                        doneColor.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 88,
                  height: 88,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    color: doneColor,
                    backgroundColor: remainingColor,
                  ),
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: surface),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: doneColor, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 130,
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
