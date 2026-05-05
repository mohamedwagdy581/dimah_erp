import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class HrFormFileService {
  static Future<void> openPdfPreview(
    BuildContext context, {
    required String title,
    required Future<Uint8List> Function() buildBytes,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _HrPdfPreviewPage(
          title: title,
          buildBytes: buildBytes,
        ),
      ),
    );
  }
}

class _HrPdfPreviewPage extends StatelessWidget {
  const _HrPdfPreviewPage({
    required this.title,
    required this.buildBytes,
  });

  final String title;
  final Future<Uint8List> Function() buildBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: PdfPreview(
        build: (_) => buildBytes(),
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowSharing: true,
        allowPrinting: true,
        pdfFileName: title,
        onError: (context, error) {
          final message = error.toString();
          final isMissingPlugin = message.contains('MissingPluginException') ||
              message.contains('printingInfo');
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.print_disabled_outlined,
                      size: 56,
                      color: Color(0xFF9A5B2A),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isMissingPlugin
                          ? 'مكوّن الطباعة لم يكتمل تحميله بعد'
                          : 'تعذر عرض معاينة المستند',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isMissingPlugin
                          ? 'نفّذ `flutter pub get` ثم أغلق التطبيق بالكامل وشغّله من جديد تشغيلًا كاملًا، وليس Hot Reload أو Hot Restart.'
                          : message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFF5D5D5D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
