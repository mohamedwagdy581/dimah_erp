import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

enum DataFailureKind { connection, forbidden, unknown }

class AppDataRegion extends StatelessWidget {
  const AppDataRegion({
    super.key,
    required this.child,
    this.loading = false,
    this.error,
    this.failed = false,
    this.onRetry,
    this.empty = false,
    this.filtered = false,
    this.onClear,
  });
  final Widget child;
  final bool loading, failed;
  final Object? error;
  final VoidCallback? onRetry;
  final bool empty, filtered;
  final VoidCallback? onClear;
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const AppLoadingState();
    }
    if (error != null || failed) {
      return AppFailureState(error: error, onRetry: onRetry);
    }
    if (empty) {
      return AppEmptyState(
        filtered: filtered,
        onClear: filtered ? onClear : null,
      );
    }
    return child;
  }
}

DataFailureKind classifyDataFailure(Object? error) {
  final value = error?.toString().toLowerCase() ?? '';
  if ([
    '42501',
    'permission denied',
    'access denied',
    'forbidden',
    'unauthorized',
    'active hr/admin',
    'hr/admin access',
    'not authorized',
    'statuscode: 403',
    'statuscode:403',
  ].any(value.contains)) {
    return DataFailureKind.forbidden;
  }
  if ([
    'socketexception',
    'clientexception',
    'failed host lookup',
    'failed to fetch',
    'networkerror',
    'network request failed',
    'connection refused',
    'network is unreachable',
    'connection closed',
    'timeoutexception',
    'timed out',
  ].any(value.contains)) {
    return DataFailureKind.connection;
  }
  return DataFailureKind.unknown;
}

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.label,
    this.rows = 5,
    this.compact = false,
  });
  final String? label;
  final int rows;
  final bool compact;
  @override
  Widget build(BuildContext context) => _StateFrame(
    maxWidth: double.infinity,
    child: LayoutBuilder(
      builder: (context, c) {
        final ar = Localizations.localeOf(context).languageCode == 'ar';
        return Semantics(
          liveRegion: true,
          label: label ?? (ar ? 'جارٍ تحميل البيانات' : 'Loading data'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!compact)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      for (var r = 0; r < math.min(rows, 6); r++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: Row(
                            children: [
                              for (
                                var col = 0;
                                col < (c.maxWidth < 400 ? 3 : 5);
                                col++
                              )
                                Expanded(
                                  flex: col == 0 ? 2 : 1,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Container(
                                      height: r == 0 ? 19 : 13,
                                      decoration: BoxDecoration(
                                        color: r.isEven
                                            ? const Color(0xFFEAEAF1)
                                            : const Color(0xFFF1F0F6),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F1FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Color(0xFFB58BDD)),
                        SizedBox(width: 7),
                        Icon(Icons.circle, size: 8, color: Color(0xFFA577D2)),
                        SizedBox(width: 7),
                        Icon(Icons.circle, size: 8, color: Color(0xFF8654BC)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label ??
                          (ar ? 'جارٍ تحميل البيانات...' : 'Loading data...'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _muted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.title,
    this.message,
    this.filtered = false,
    this.onClear,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });
  final String? title, message, actionLabel;
  final bool filtered, compact;
  final VoidCallback? onClear, onAction;
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String a, String e) => ar ? a : e;
    return _StateContent(
      compact: compact,
      kind: filtered ? _ArtKind.search : _ArtKind.document,
      title:
          title ??
          (filtered
              ? tr('لا توجد نتائج مطابقة', 'No matching results')
              : tr('لا توجد بيانات حاليًا', 'No data yet')),
      message:
          message ??
          (filtered
              ? tr(
                  'جرّب تغيير معايير البحث أو مسح الفلاتر.',
                  'Try changing your search or clearing the filters.',
                )
              : tr(
                  'ستظهر البيانات هنا عند توفرها.',
                  'Data will appear here when available.',
                )),
      actionLabel: onClear != null
          ? tr('مسح الفلاتر', 'Clear filters')
          : actionLabel,
      onAction: onClear ?? onAction,
      actionIcon: onClear != null ? Icons.close : Icons.add,
    );
  }
}

class AppFailureState extends StatelessWidget {
  const AppFailureState({
    super.key,
    this.error,
    this.onRetry,
    this.title,
    this.message,
    this.compact = false,
  });
  final Object? error;
  final VoidCallback? onRetry;
  final String? title, message;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String a, String e) => ar ? a : e;
    final kind = classifyDataFailure(error);
    if (kind == DataFailureKind.forbidden) {
      return AppAccessDeniedState(compact: compact);
    }
    return _StateContent(
      compact: compact,
      kind: _ArtKind.cloud,
      title: kind == DataFailureKind.connection
          ? tr('تعذّر الاتصال بالخدمة', 'Could not connect')
          : title ?? tr('تعذّر تحميل البيانات', 'Unable to load data'),
      message:
          message ??
          (kind == DataFailureKind.connection
              ? tr(
                  'تحقق من اتصال الإنترنت، ثم أعد المحاولة.',
                  'Check your internet connection, then retry.',
                )
              : tr(
                  'حدث خطأ أثناء جلب البيانات من النظام.\nيرجى المحاولة مرة أخرى.',
                  'An error occurred while fetching data.\nPlease try again.',
                )),
      onAction: onRetry,
      actionLabel: tr('إعادة المحاولة', 'Retry'),
      actionIcon: Icons.refresh,
    );
  }
}

class AppAccessDeniedState extends StatelessWidget {
  const AppAccessDeniedState({super.key, this.compact = false, this.onHome});
  final bool compact;
  final VoidCallback? onHome;
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return _StateContent(
      compact: compact,
      kind: _ArtKind.shield,
      title: ar
          ? 'لا تملك صلاحية عرض هذه الصفحة'
          : 'You do not have access to this page',
      message: ar
          ? 'يرجى العودة إلى الصفحة الرئيسية أو التواصل مع مسؤول النظام.'
          : 'Return to the home page or contact your system administrator.',
      onAction: onHome ?? () => GoRouter.maybeOf(context)?.go('/'),
      actionLabel: ar ? 'العودة للرئيسية' : 'Back to home',
      actionIcon: Icons.home_outlined,
    );
  }
}

const _ink = Color(0xFF171359),
    _muted = Color(0xFF777098),
    _purple = Color(0xFF8654BC),
    _border = Color(0xFFE8E2F4);

class _StateFrame extends StatelessWidget {
  const _StateFrame({required this.child, this.maxWidth = 720});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => SingleChildScrollView(
      primary: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: c.hasBoundedHeight ? c.maxHeight : 0,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

enum _ArtKind { document, search, cloud, shield }

class _StateContent extends StatelessWidget {
  const _StateContent({
    required this.kind,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.refresh,
    this.compact = false,
  });
  final _ArtKind kind;
  final String title, message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final bool compact;
  @override
  Widget build(BuildContext context) => _StateFrame(
    child: Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            SizedBox(
              width: 140,
              height: 130,
              child: CustomPaint(painter: _StateArt(kind)),
            ),
            const SizedBox(height: 22),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 14, height: 1.7),
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 24),
            if (kind == _ArtKind.search || kind == _ArtKind.shield)
              OutlinedButton.icon(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple,
                  side: const BorderSide(color: _purple),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                icon: Icon(actionIcon, size: 20),
                label: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              FilledButton.icon(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                icon: Icon(actionIcon, size: 20),
                label: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ],
      ),
    ),
  );
}

class _StateArt extends CustomPainter {
  const _StateArt(this.kind);
  final _ArtKind kind;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 140, size.height / 130);
    final stroke = Paint()
      ..color = const Color(0xFFB398E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = const Color(0xFFF4EEFF);
    switch (kind) {
      case _ArtKind.document:
        final path = Path()
          ..moveTo(38, 18)
          ..lineTo(78, 18)
          ..lineTo(104, 43)
          ..lineTo(104, 107)
          ..quadraticBezierTo(104, 114, 96, 114)
          ..lineTo(38, 114)
          ..quadraticBezierTo(31, 114, 31, 107)
          ..lineTo(31, 25)
          ..quadraticBezierTo(31, 18, 38, 18)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(78, 18)
            ..lineTo(78, 43)
            ..lineTo(104, 43),
          stroke,
        );
        for (final y in [57.0, 74.0, 91.0]) {
          canvas.drawLine(Offset(48, y), Offset(84, y), stroke);
        }
      case _ArtKind.search:
        canvas.drawCircle(const Offset(60, 55), 32, fill);
        canvas.drawCircle(const Offset(60, 55), 32, stroke);
        canvas.drawLine(const Offset(84, 79), const Offset(116, 111), stroke);
      case _ArtKind.cloud:
        final path = Path()
          ..moveTo(36, 88)
          ..cubicTo(8, 88, 11, 56, 28, 53)
          ..cubicTo(22, 30, 49, 26, 58, 33)
          ..cubicTo(73, 9, 109, 22, 108, 50)
          ..cubicTo(139, 56, 129, 88, 107, 88)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        canvas.drawCircle(
          const Offset(77, 83),
          19,
          Paint()..color = const Color(0xFFFF4356),
        );
        final white = Paint()
          ..color = Colors.white
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(77, 72), const Offset(77, 83), white);
        canvas.drawCircle(const Offset(77, 91), 2, white);
      case _ArtKind.shield:
        final path = Path()
          ..moveTo(70, 11)
          ..lineTo(113, 29)
          ..lineTo(113, 61)
          ..quadraticBezierTo(111, 96, 70, 120)
          ..quadraticBezierTo(29, 96, 27, 61)
          ..lineTo(27, 29)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(54, 59, 33, 30),
            const Radius.circular(5),
          ),
          Paint()..color = _purple,
        );
        canvas.drawArc(
          const Rect.fromLTWH(59, 43, 23, 31),
          math.pi,
          math.pi,
          false,
          stroke..color = _purple,
        );
        canvas.drawCircle(
          const Offset(70, 70),
          3,
          Paint()..color = Colors.white,
        );
        canvas.drawLine(
          const Offset(70, 72),
          const Offset(70, 78),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 3,
        );
    }
    stroke.color = const Color(0xFFAE8CDF);
    canvas.drawLine(const Offset(119, 20), const Offset(125, 13), stroke);
    canvas.drawLine(const Offset(123, 36), const Offset(132, 36), stroke);
    canvas.drawCircle(
      const Offset(17, 105),
      3,
      Paint()..color = const Color(0xFFAE8CDF),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StateArt oldDelegate) =>
      kind != oldDelegate.kind;
}
