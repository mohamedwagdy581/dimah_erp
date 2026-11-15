import 'package:flutter/material.dart';
import '../../core/ui/employee_theme.dart';
import '../employees/view/utils/employee_profile_utils.dart';

class AttendanceEmployeeAvatar extends StatelessWidget {
  const AttendanceEmployeeAvatar({
    super.key,
    required this.name,
    this.photoUrl,
  });
  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final initials = words
        .take(2)
        .map((w) => w.characters.first)
        .join(' ')
        .toUpperCase();
    final photo = resolveEmployeePhotoProvider(photoUrl);
    return CircleAvatar(
      radius: 18,
      backgroundColor: EmployeeTheme.primary.withValues(alpha: .16),
      foregroundImage: photo,
      onForegroundImageError: photo == null ? null : (_, _) {},
      child: Text(
        initials.isEmpty ? '—' : initials,
        style: const TextStyle(
          color: EmployeeTheme.dark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
