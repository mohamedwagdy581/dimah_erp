import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HrFormPreviewService {
  static Future<void> openDesignPreview(
    BuildContext context, {
    required String title,
    required Widget child,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _HrDesignPreviewPage(title: title, child: child),
      ),
    );
  }
}

class _HrDesignPreviewPage extends StatefulWidget {
  const _HrDesignPreviewPage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  State<_HrDesignPreviewPage> createState() => _HrDesignPreviewPageState();
}

class _HrDesignPreviewPageState extends State<_HrDesignPreviewPage> {
  final GlobalKey _previewKey = GlobalKey();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Print',
            onPressed: _busy ? null : _printPreview,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_outlined),
          ),
          IconButton(
            tooltip: 'Save PDF',
            onPressed: _busy ? null : _savePdf,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF2F5F7),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: RepaintBoundary(key: _previewKey, child: widget.child),
          ),
        ),
      ),
    );
  }

  Future<void> _printPreview() async {
    final messenger = ScaffoldMessenger.of(context);
    await _runBusy(() async {
      final imageBytes = await _capturePreviewPng();
      if (imageBytes == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to capture preview for printing'),
          ),
        );
        return;
      }
      await Printing.layoutPdf(
        onLayout: (format) => _buildPdfFromImage(imageBytes, format),
        name: _pdfFileName,
      );
    });
  }

  Future<void> _savePdf() async {
    final messenger = ScaffoldMessenger.of(context);
    await _runBusy(() async {
      final imageBytes = await _capturePreviewPng();
      if (imageBytes == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Failed to capture preview as PDF')),
        );
        return;
      }
      final pdfBytes = await _buildPdfFromImage(imageBytes, PdfPageFormat.a4);
      await Printing.sharePdf(bytes: pdfBytes, filename: _pdfFileName);
    });
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<Uint8List?> _capturePreviewPng() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final boundary =
        _previewKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<Uint8List> _buildPdfFromImage(
    Uint8List imageBytes,
    PdfPageFormat format,
  ) async {
    final document = pw.Document();
    final image = pw.MemoryImage(imageBytes);
    document.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(18),
        build: (context) {
          return pw.Center(
            child: pw.FittedBox(fit: pw.BoxFit.contain, child: pw.Image(image)),
          );
        },
      ),
    );
    return document.save();
  }

  String get _pdfFileName {
    final sanitized = widget.title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(' ', '_');
    return '$sanitized.pdf';
  }
}
