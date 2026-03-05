import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder tablet;
  final WidgetBuilder desktop;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    if (w < AppBreakpoints.mobile) return mobile(context);
    if (w < AppBreakpoints.tablet) return tablet(context);
    return desktop(context);
  }
}
