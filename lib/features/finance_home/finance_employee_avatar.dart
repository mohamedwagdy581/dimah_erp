import 'package:material_ui/material_ui.dart';
import '../accounting/view/accounting_ui.dart';
import '../employees/view/utils/employee_profile_utils.dart';

class FinanceEmployeeAvatar extends StatelessWidget {
  const FinanceEmployeeAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 24,
  });
  final String name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first)
        .join(' ')
        .toUpperCase();
    final photo = resolveEmployeePhotoProvider(photoUrl);
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFF0E5FF),
      foregroundImage: photo,
      onForegroundImageError: photo == null ? null : (_, _) {},
      child: Text(
        initials.isEmpty ? '—' : initials,
        style: TextStyle(
          color: accountingPurple,
          fontSize: radius * .6,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
