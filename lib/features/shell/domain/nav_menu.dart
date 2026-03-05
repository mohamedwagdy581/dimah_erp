import '../../../core/routing/app_routes.dart';
import 'nav_item.dart';
import 'package:flutter/material.dart';

class NavMenu {
  static List<NavItem> forRole(String role) {
    final all = <NavItem>[
      NavItem(
        path: AppRoutes.dashboard,
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        allowedRoles: const [
          'admin',
          'hr',
          'manager',
          'accountant',
          'employee',
        ],
        section: 'عام',
        keywords: const [
          'dashboard',
          'home',
          'الرئيسية',
          'لوحة',
        ],
      ),
      NavItem(
        path: AppRoutes.departments,
        label: 'Departments',
        icon: Icons.apartment_outlined,
        allowedRoles: const ['admin', 'hr'],
        section: 'الموارد البشرية',
        keywords: const [
          'department',
          'departments',
          'قسم',
          'الأقسام',
        ],
      ),
      NavItem(
        path: AppRoutes.jobTitles,
        label: 'Job Titles',
        icon: Icons.work_outline,
        allowedRoles: const ['admin', 'hr'],
        section: 'الموارد البشرية',
        keywords: const [
          'job',
          'title',
          'titles',
          'وظيفة',
          'الوظائف',
          'المسميات',
        ],
      ),
      NavItem(
        path: AppRoutes.employees,
        label: 'Employees',
        icon: Icons.badge_outlined,
        allowedRoles: const ['admin', 'hr', 'manager'],
        section: 'الموارد البشرية',
        keywords: const [
          'employee',
          'employees',
          'staff',
          'موظف',
          'الموظفين',
        ],
      ),
      NavItem(
        path: AppRoutes.attendance,
        label: 'Attendance',
        icon: Icons.calendar_month_outlined,
        allowedRoles: const ['admin', 'hr', 'manager'],
        section: 'الموارد البشرية',
        keywords: const [
          'attendance',
          'checkin',
          'checkout',
          'حضور',
          'انصراف',
          'دوام',
        ],
      ),
      NavItem(
        path: AppRoutes.leaves,
        label: 'Leaves',
        icon: Icons.event_note_outlined,
        allowedRoles: const ['admin', 'hr', 'manager'],
        section: 'الموارد البشرية',
        keywords: const [
          'leave',
          'leaves',
          'vacation',
          'اجازة',
          'إجازات',
        ],
      ),
      NavItem(
        path: AppRoutes.payroll,
        label: 'Payroll',
        icon: Icons.request_quote_outlined,
        allowedRoles: const ['admin', 'hr', 'accountant'],
        section: 'الموارد البشرية',
        keywords: const [
          'payroll',
          'salary',
          'salaries',
          'رواتب',
          'مرتب',
        ],
      ),
      NavItem(
        path: AppRoutes.employeeDocs,
        label: 'Employee Documents',
        icon: Icons.folder_shared_outlined,
        allowedRoles: const ['admin', 'hr'],
        section: 'الموارد البشرية',
        keywords: const [
          'documents',
          'docs',
          'contract',
          'عقود',
          'مستندات',
          'ملفات',
        ],
      ),
      NavItem(
        path: AppRoutes.hrAlerts,
        label: 'HR Alerts',
        icon: Icons.notifications_active_outlined,
        allowedRoles: const ['admin', 'hr'],
        section: 'Ø§Ù„Ù…ÙˆØ§Ø±Ø¯ Ø§Ù„Ø¨Ø´Ø±ÙŠØ©',
        keywords: const [
          'alerts',
          'expiry',
          'contract',
          'insurance',
          'residency',
          'alerts hr',
          'ØªÙ†Ø¨ÙŠÙ‡Ø§Øª',
          'Ø¥Ù†Ø°Ø§Ø±Ø§Øª',
        ],
      ),
      NavItem(
        path: AppRoutes.approvals,
        label: 'Approvals',
        icon: Icons.approval_outlined,
        allowedRoles: const ['admin', 'hr', 'manager'],
        section: 'الموارد البشرية',
        keywords: const [
          'approval',
          'approvals',
          'موافقة',
          'موافقات',
          'طلبات',
        ],
      ),
      NavItem(
        path: AppRoutes.myPortal,
        label: 'My Portal',
        icon: Icons.person_outline,
        allowedRoles: const ['employee'],
        section: 'الموظف',
        keywords: const [
          'my',
          'portal',
          'profile',
          'موظف',
          'حسابي',
        ],
      ),
      NavItem(
        path: AppRoutes.accounts,
        label: 'Accounts',
        icon: Icons.account_balance_outlined,
        allowedRoles: const ['admin', 'accountant'],
        section: 'المحاسبة',
        keywords: const [
          'accounts',
          'coa',
          'chart',
          'حسابات',
          'دليل',
        ],
      ),
      NavItem(
        path: AppRoutes.journal,
        label: 'Journal',
        icon: Icons.menu_book_outlined,
        allowedRoles: const ['admin', 'accountant'],
        section: 'المحاسبة',
        keywords: const [
          'journal',
          'entries',
          'قيد',
          'قيود',
          'يومية',
        ],
      ),
    ];

    return all.where((e) => e.allowedRoles.contains(role)).toList();
  }

  static List<NavItem> searchableForRole(String role) {
    final menu = forRole(role);

    return [
      ...menu,
      const NavItem(
        path: '/profile',
        label: 'My Profile',
        icon: Icons.person_outline,
        allowedRoles: ['admin', 'hr', 'manager', 'accountant', 'employee'],
        section: 'الحساب',
        keywords: ['profile', 'account', 'الحساب', 'الملف الشخصي'],
      ),
      const NavItem(
        path: '/change-password',
        label: 'Change Password',
        icon: Icons.lock_outline,
        allowedRoles: ['admin', 'hr', 'manager', 'accountant', 'employee'],
        section: 'الحساب',
        keywords: ['password', 'security', 'كلمة المرور', 'السرية'],
      ),
    ].where((e) => e.allowedRoles.contains(role)).toList();
  }
}
