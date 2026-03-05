import 'package:flutter/material.dart';

class AppText {
  static const fontFamily = 'Cairo'; // أو أي خط هتحطه

  static TextStyle h1(BuildContext context) => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: fontFamily,
  );

  static TextStyle h2(BuildContext context) => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    fontFamily: fontFamily,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
  );

  static const small = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
  );
}
