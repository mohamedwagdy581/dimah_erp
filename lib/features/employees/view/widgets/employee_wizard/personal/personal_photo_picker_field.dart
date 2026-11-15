import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/utils/safe_file_picker.dart';
import '../../../../../../l10n/app_localizations.dart';

class PersonalPhotoPickerField extends StatefulWidget {
  const PersonalPhotoPickerField({
    super.key,
    required this.photoUrl,
    required this.onChanged,
  });

  final String photoUrl;
  final ValueChanged<String> onChanged;

  @override
  State<PersonalPhotoPickerField> createState() =>
      _PersonalPhotoPickerFieldState();
}

class _PersonalPhotoPickerFieldState extends State<PersonalPhotoPickerField> {
  static const int _maxPhotoBytes = 2 * 1024 * 1024;
  bool _picking = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final hasPhoto = widget.photoUrl.trim().isNotEmpty;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Material(
      color: const Color(0xFFFAF7FF),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _picking ? null : _pickOnly,
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: _PhotoBorder(),
          child: SizedBox(
            height: 246,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_picking)
                    const SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(),
                    )
                  else if (hasPhoto)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(
                        image: _resolvePhotoProvider(widget.photoUrl),
                        width: 94,
                        height: 94,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stack) => const Icon(
                          Icons.broken_image_outlined,
                          size: 44,
                          color: Color(0xFF8654BC),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFECE2FF),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Color(0xFF8028ED),
                        size: 27,
                      ),
                    ),
                  const SizedBox(height: 14),
                  Text(
                    _picking
                        ? t.picking
                        : (hasPhoto
                              ? (ar
                                    ? 'تغيير صورة الموظف'
                                    : 'Change employee photo')
                              : (ar
                                    ? 'إضافة صورة (اختياري)'
                                    : 'Add a photo (optional)')),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8028ED),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'JPG / PNG',
                    style: TextStyle(fontSize: 11, color: Color(0xFF777098)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    ar ? 'الحد الأقصى 2 ميجابايت' : 'Maximum 2 MB',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF777098),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ImageProvider _resolvePhotoProvider(String rawValue) {
    final value = rawValue.trim();
    final uri = Uri.tryParse(value);
    if (uri != null) {
      final scheme = uri.scheme.toLowerCase();
      if (scheme == 'http' || scheme == 'https') return NetworkImage(value);
      if (scheme == 'file') return FileImage(File(uri.toFilePath()));
    }
    return FileImage(File(value));
  }

  Future<void> _pickOnly() async {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final file = await SafeFilePicker.openSingle(
      context: context,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Images', extensions: ['png', 'jpg', 'jpeg']),
      ],
    );
    if (file == null || !mounted) return;
    setState(() => _picking = true);
    try {
      if (await file.length() > _maxPhotoBytes) {
        throw Exception(
          ar ? 'الحد الأقصى للصورة 2 ميجابايت' : 'Photo must be at most 2 MB',
        );
      }
      if (file.path.isEmpty) throw Exception(t.unableAccessSelectedFilePath);
      if (!mounted) return;
      widget.onChanged(file.path);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.photoSelectedUploadAfterCreate)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.photoUploadFailed(error.toString()))),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }
}

class _PhotoBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      );
    final paint = Paint()
      ..color = const Color(0xFFD9C5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 8) {
        canvas.drawPath(
          metric.extractPath(offset, (offset + 4).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
