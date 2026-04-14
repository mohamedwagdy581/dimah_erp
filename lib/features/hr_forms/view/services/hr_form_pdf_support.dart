import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

Future<pw.ThemeData?> loadHrFormPdfTheme() async {
  if (!Platform.isWindows) return null;
  final base = await _loadFont([
    r'C:\Windows\Fonts\arial.ttf',
    r'C:\Windows\Fonts\segoeui.ttf',
  ]);
  if (base == null) return null;
  final bold = await _loadFont([
    r'C:\Windows\Fonts\arialbd.ttf',
    r'C:\Windows\Fonts\segoeuib.ttf',
  ]);
  return pw.ThemeData.withFont(base: base, bold: bold ?? base);
}

Future<pw.Font?> _loadFont(List<String> candidates) async {
  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) {
      final bytes = await file.readAsBytes();
      return pw.Font.ttf(ByteData.view(bytes.buffer));
    }
  }
  return null;
}

Future<pw.MemoryImage> loadHrFormLogo() async {
  final data = await rootBundle.load('assets/images/fullLogo.png');
  return pw.MemoryImage(data.buffer.asUint8List());
}
