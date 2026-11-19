import 'package:material_ui/material_ui.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/employee_profile_details.dart';
import '../../utils/employee_profile_utils.dart';

class EmployeeProfileIdentityHeader extends StatelessWidget {
  const EmployeeProfileIdentityHeader({
    super.key,
    required this.profile,
    required this.canEdit,
    required this.onDownload,
    this.onEdit,
    this.onIdentity,
    this.onLogin,
    this.onBack,
    this.onStatus,
  });
  final EmployeeProfileDetails profile;
  final bool canEdit;
  final VoidCallback onDownload;
  final VoidCallback? onEdit, onIdentity, onBack, onLogin, onStatus;
  static const accent = Color(0xFF8659BB);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final p = profile;
    final initials = p.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s.characters.first)
        .join(' ')
        .toUpperCase();
    final status = switch (p.status) {
      'active' => ar ? 'على رأس العمل' : 'Active',
      'probation' => ar ? 'فترة تجربة' : 'Probation',
      'inactive' => t.inactive,
      _ => p.status,
    };
    Widget info(IconData icon, String label, String? value, double width) =>
        SizedBox(
          width: width,
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: accent.withValues(alpha: .09),
                child: Icon(icon, color: accent, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF66638B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (value ?? '').isEmpty ? '—' : value!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    final identity = Row(
      children: [
        CircleAvatar(
          radius: 29,
          backgroundColor: accent.withValues(alpha: .13),
          foregroundImage: resolveEmployeePhotoProvider(p.photoUrl),
          onForegroundImageError: (p.photoUrl ?? '').trim().isEmpty
              ? null
              : (_, _) {},
          child: Text(
            initials,
            style: const TextStyle(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.fullName,
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF17154B),
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if ((p.employeeNumber ?? '').isNotEmpty)
                Text(
                  p.employeeNumber!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF66638B),
                  ),
                ),
              Text(
                [
                  p.jobTitleName,
                  p.departmentName,
                ].whereType<String>().where((s) => s.isNotEmpty).join(' — '),
                style: const TextStyle(fontSize: 13, color: Color(0xFF66638B)),
              ),
            ],
          ),
        ),
      ],
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            status,
            style: const TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          tooltip: t.downloadReport,
          onPressed: onDownload,
          icon: const Icon(Icons.download_outlined, size: 18),
        ),
        if (canEdit)
          IconButton(
            tooltip: t.editProfile,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        if (canEdit && onIdentity != null)
          IconButton(
            tooltip: ar ? 'رقم البصمة' : 'Device employee number',
            onPressed: onIdentity,
            icon: const Icon(Icons.fingerprint, size: 18),
          ),
        if (canEdit && onLogin != null)
          IconButton(
            tooltip: Localizations.localeOf(context).languageCode == 'ar'
                ? 'تجهيز حساب الدخول'
                : 'Set up employee login',
            onPressed: onLogin,
            icon: const Icon(Icons.manage_accounts_outlined, size: 20),
          ),
        if (onBack != null)
          IconButton(
            onPressed: onBack,
            tooltip: ar ? 'قائمة الموظفين' : 'Employee directory',
            icon: const Icon(Icons.people_outline, size: 18),
          ),
        if (canEdit && onStatus != null)
          OutlinedButton.icon(
            onPressed: onStatus,
            icon: Icon(
              p.status == 'inactive'
                  ? Icons.person_add_alt_1
                  : Icons.person_off_outlined,
              size: 18,
            ),
            label: Text(
              p.status == 'inactive'
                  ? (ar ? 'إعادة التفعيل' : 'Reactivate')
                  : (ar ? 'إيقاف الموظف' : 'Deactivate'),
            ),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (box.maxWidth >= 850)
            Row(
              children: [
                Expanded(child: identity),
                const SizedBox(width: 20),
                actions,
              ],
            )
          else ...[
            identity,
            const SizedBox(height: 8),
            actions,
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: accent.withValues(alpha: .14)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: LayoutBuilder(
              builder: (context, box) {
                final columns = box.maxWidth >= 900
                    ? 4
                    : box.maxWidth >= 500
                    ? 2
                    : 1;
                final width = (box.maxWidth - 16 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 18,
                  children: [
                    info(
                      Icons.calendar_month_outlined,
                      t.hireDate,
                      formatEmployeeDate(p.hireDate).replaceAll('-', '/'),
                      width,
                    ),
                    info(
                      Icons.work_outline,
                      t.menuJobTitles,
                      p.jobTitleName,
                      width,
                    ),
                    info(
                      Icons.groups_outlined,
                      t.department,
                      p.departmentName,
                      width,
                    ),
                    info(
                      Icons.person_outline,
                      ar ? 'المدير المباشر' : 'Direct manager',
                      p.managerName,
                      width,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
