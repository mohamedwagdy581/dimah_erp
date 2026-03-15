part of 'nav_menu.dart';

const _searchOnlyNavItems = <NavItem>[
  NavItem(
    path: '/profile',
    label: 'My Profile',
    icon: Icons.person_outline,
    allowedRoles: ['admin', 'hr', 'manager', 'accountant', 'employee'],
    section: _accountSection,
    keywords: ['profile', 'account', 'الحساب', 'الملف الشخصي'],
  ),
  NavItem(
    path: '/change-password',
    label: 'Change Password',
    icon: Icons.lock_outline,
    allowedRoles: ['admin', 'hr', 'manager', 'accountant', 'employee'],
    section: _accountSection,
    keywords: ['password', 'security', 'كلمة المرور', 'السرية'],
  ),
];
