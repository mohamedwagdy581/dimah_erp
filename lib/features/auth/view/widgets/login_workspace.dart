import 'dart:math' as math;
import '../../../../core/ui/app_assets.dart';
import 'package:material_ui/material_ui.dart';

class LoginWorkspace extends StatelessWidget {
  const LoginWorkspace({super.key, required this.form});
  final Widget form;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 780;
        final width = math.min(1120.0, constraints.maxWidth - (wide ? 48 : 24));
        final ar = Localizations.localeOf(context).languageCode == 'ar';
        final content = Padding(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 48 : 22,
            vertical: wide ? 48 : 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: form,
              ),
            ],
          ),
        );
        return SingleChildScrollView(
          key: const ValueKey('login-page-scroll'),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: SizedBox(
                  width: width,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8E2F4)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D583186),
                          blurRadius: 26,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: ColoredBox(
                        color: Colors.white,
                        child: wide
                            ? Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    width: width * .39,
                                    child: _Brand(ar: ar),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: width * .39),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minHeight: 540,
                                      ),
                                      child: content,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 200,
                                    width: double.infinity,
                                    child: _Brand(ar: ar, compact: true),
                                  ),
                                  content,
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _Brand extends StatelessWidget {
  const _Brand({required this.ar, this.compact = false});
  final bool ar, compact;
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BrandPainter(),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 28,
        vertical: compact ? 16 : 54,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppAssets.whiteLogo,
              height: compact ? 84 : 150,
              fit: BoxFit.contain,
            ),
            SizedBox(height: compact ? 12 : 30),
            Text(
              'DIMAH ERP',
              style: TextStyle(
                fontSize: compact ? 18 : 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 9),
              Text(
                ar
                    ? 'منصة إدارة الموارد البشرية\nلتحقيق كفاءة أعلى لبيئة العمل'
                    : 'Human resources management\nfor a more efficient workplace',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.7,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _BrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA47DCA), Color(0xFF835BB6), Color(0xFF64439D)],
        ).createShader(rect),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .4)
        ..quadraticBezierTo(
          size.width * .4,
          size.height * .12,
          size.width,
          size.height * .14,
        )
        ..lineTo(size.width, size.height * .86)
        ..quadraticBezierTo(
          size.width * .4,
          size.height * .76,
          0,
          size.height * .95,
        )
        ..close(),
      Paint()..color = const Color(0x305C3993),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * .48, 0)
        ..lineTo(0, size.height * .3)
        ..close(),
      Paint()..color = const Color(0x16FFFFFF),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .24)
        ..quadraticBezierTo(
          size.width * .52,
          size.height * .34,
          size.width,
          size.height * .6,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height * .66)
        ..close(),
      Paint()..color = const Color(0x186546A0),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .75)
        ..quadraticBezierTo(
          size.width * .5,
          size.height * 1.02,
          size.width,
          size.height * .94,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = const Color(0x12FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _BrandPainter oldDelegate) => false;
}
