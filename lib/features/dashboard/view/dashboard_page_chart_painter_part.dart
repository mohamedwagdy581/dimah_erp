part of 'dashboard_page.dart';

class _LineTrendPainter extends CustomPainter {
  _LineTrendPainter({
    required this.series,
    required this.color,
    required this.factor,
    required this.textColor,
  });

  final List<_MonthlyMetricPoint> series;
  final Color color;
  final double factor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 24;
    final chartWidth = size.width;
    final gridPaint = Paint()
      ..color = textColor.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = chartHeight * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    final maxValue = series.fold<double>(
      0,
      (max, item) => item.value > max ? item.value : max,
    );
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final stepX = series.length == 1 ? 0.0 : chartWidth / (series.length - 1);
    final path = Path();
    for (var i = 0; i < series.length; i++) {
      final item = series[i];
      final x = stepX * i;
      final y = chartHeight - ((item.value / safeMax) * chartHeight * factor);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    final fillPath = Path.from(path)
      ..lineTo(chartWidth, chartHeight)
      ..lineTo(0, chartHeight)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    for (var i = 0; i < series.length; i++) {
      final item = series[i];
      final x = stepX * i;
      final y = chartHeight - ((item.value / safeMax) * chartHeight * factor);
      canvas.drawCircle(
        Offset(x, y),
        4.5,
        Paint()..color = color,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: item.value.toStringAsFixed(0),
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - (tp.width / 2), y - 18));
    }
  }

  @override
  bool shouldRepaint(covariant _LineTrendPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.color != color ||
        oldDelegate.factor != factor ||
        oldDelegate.textColor != textColor;
  }
}
