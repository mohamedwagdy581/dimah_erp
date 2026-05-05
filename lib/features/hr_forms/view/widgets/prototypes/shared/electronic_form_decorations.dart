import 'package:flutter/material.dart';

import 'electronic_form_theme.dart';

class ElectronicHeaderDecoration extends StatelessWidget {
  const ElectronicHeaderDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -ElectronicFormDimensions.headerHeight * 0.5,
      left: -160,
      child: Transform.rotate(
        angle: -0.70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: ElectronicFormDimensions.headerWidth,
              height: ElectronicFormDimensions.headerHeight,
              decoration: BoxDecoration(
                color: ElectronicFormColors.headerSurface,
                borderRadius: BorderRadius.circular(
                  ElectronicFormDimensions.headerRadius,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ElectronicFormColors.footerShadowB.withOpacity(0.20),
                    blurRadius: 24,
                    offset: const Offset(4, 8),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(
                ElectronicFormDimensions.headerAccentOffset,
                0,
              ),
              child: ClipPath(
                clipper: _DoubleDiagonalEdgeClipper(),
                child: Container(
                  width: ElectronicFormDimensions.headerAccentWidth,
                  height: ElectronicFormDimensions.headerAccentHeight,
                  decoration: BoxDecoration(
                    color: ElectronicFormColors.headerAccent,
                    boxShadow: [
                      BoxShadow(
                        color: ElectronicFormColors.footerShadowB.withOpacity(
                          0.18,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoubleDiagonalEdgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - 24, size.height)
      ..lineTo(24, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class ElectronicFooterDecoration extends StatelessWidget {
  const ElectronicFooterDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ElectronicFormDimensions.footerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: -100,
            right: -80,
            child: Transform.rotate(
              angle: -0.30,
              child: Container(
                width: ElectronicFormDimensions.footerShape1Width,
                height: ElectronicFormDimensions.footerHeight,
                decoration: BoxDecoration(
                  color: ElectronicFormColors.footerSurface,
                  borderRadius: BorderRadius.circular(
                    ElectronicFormDimensions.footerShapeRadius,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ElectronicFormColors.footerShadowA.withOpacity(
                        0.18,
                      ),
                      blurRadius: ElectronicFormDimensions.footerShadowBlur,
                      offset: const Offset(
                        0,
                        ElectronicFormDimensions.footerShadowOffset,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -60,
            child: Transform.rotate(
              angle: 0.20,
              child: Container(
                width: ElectronicFormDimensions.footerShape2Width,
                height: ElectronicFormDimensions.footerHeight,
                decoration: BoxDecoration(
                  color: ElectronicFormColors.footerAccent,
                  borderRadius: BorderRadius.circular(
                    ElectronicFormDimensions.footerShapeRadius,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ElectronicFormColors.footerShadowB.withOpacity(
                        0.16,
                      ),
                      blurRadius: ElectronicFormDimensions.footerShadowBlur,
                      offset: const Offset(
                        0,
                        ElectronicFormDimensions.footerShadowOffset,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
