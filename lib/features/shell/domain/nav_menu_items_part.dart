part of 'nav_menu.dart';

const _generalSection = 'عام';
const _hrSection = 'الموارد البشرية';
const _employeeSection = 'الموظف';
const _accountingSection = 'المحاسبة';
const _accountSection = 'الحساب';

const _allNavItems = <NavItem>[
  NavItem(
    path: AppRoutes.dashboard,
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    allowedRoles: ['admin', 'hr', 'manager', 'accountant', 'employee'],
    section: _generalSection,
    keywords: ['dashboard', 'home', 'الرئيسية', 'لوحة'],
  ),
  NavItem(
    path: AppRoutes.departments,
    label: 'Departments',
    icon: Icons.apartment_outlined,
    allowedRoles: ['admin', 'hr'],
    section: _hrSection,
    keywords: ['department', 'departments', 'قسم', 'الأقسام'],
  ),
  NavItem(
    path: AppRoutes.jobTitles,
    label: 'Job Titles',
    icon: Icons.work_outline,
    allowedRoles: ['admin', 'hr'],
    section: _hrSection,
    keywords: ['job', 'title', 'titles', 'وظيفة', 'الوظائف', 'المسميات'],
  ),
  NavItem(
    path: AppRoutes.employees,
    label: 'Employees',
    icon: Icons.badge_outlined,
    allowedRoles: ['admin', 'hr', 'manager'],
    section: _hrSection,
    keywords: ['employee', 'employees', 'staff', 'موظف', 'الموظفين'],
  ),
  NavItem(
    path: AppRoutes.attendance,
    label: 'Attendance',
    icon: Icons.calendar_month_outlined,
    allowedRoles: ['admin', 'hr', 'manager'],
    section: _hrSection,
    keywords: ['attendance', 'checkin', 'checkout', 'حضور', 'انصراف', 'دوام'],
  ),
  NavItem(
    path: AppRoutes.leaves,
    label: 'Leaves',
    icon: Icons.event_note_outlined,
    allowedRoles: ['admin', 'hr', 'manager'],
    section: _hrSection,
    keywords: ['leave', 'leaves', 'vacation', 'اجازة', 'إجازات'],
  ),
  NavItem(
    path: AppRoutes.payroll,
    label: 'Payroll',
    icon: Icons.request_quote_outlined,
    allowedRoles: ['admin', 'hr', 'accountant'],
    section: _hrSection,
    keywords: ['payroll', 'salary', 'salaries', 'رواتب', 'مرتب'],
  ),
  NavItem(
    path: AppRoutes.employeeDocs,
    label: 'Employee Documents',
    icon: Icons.folder_shared_outlined,
    allowedRoles: ['admin', 'hr'],
    section: _hrSection,
    keywords: ['documents', 'docs', 'contract', 'عقود', 'مستندات', 'ملفات'],
  ),
  NavItem(
    path: AppRoutes.hrAlerts,
    label: 'HR Alerts',
    icon: Icons.notifications_active_outlined,
    allowedRoles: ['admin', 'hr'],
    section: _hrSection,
    keywords: [
      'alerts',
      'expiry',
      'contract',
      'insurance',
      'residency',
      'alerts hr',
      'تنبيهات',
      'إنذارات',
    ],
  ),
  NavItem(
    path: AppRoutes.approvals,
    label: 'Approvals',
    icon: Icons.approval_outlined,
    allowedRoles: ['admin', 'hr', 'manager'],
    section: _hrSection,
    keywords: ['approval', 'approvals', 'موافقة', 'موافقات', 'طلبات'],
  ),
  NavItem(
    path: AppRoutes.myPortal,
    label: 'My Portal',
    icon: Icons.person_outline,
    allowedRoles: ['employee'],
    section: _employeeSection,
    keywords: ['my', 'portal', 'profile', 'موظف', 'حسابي'],
  ),
  NavItem(
    path: AppRoutes.accounts,
    label: 'Accounts',
    icon: Icons.account_balance_outlined,
    allowedRoles: ['admin', 'accountant'],
    section: _accountingSection,
    keywords: ['accounts', 'coa', 'chart', 'حسابات', 'دليل'],
  ),
  NavItem(
    path: AppRoutes.journal,
    label: 'Journal',
    icon: Icons.menu_book_outlined,
    allowedRoles: ['admin', 'accountant'],
    section: _accountingSection,
    keywords: ['journal', 'entries', 'قيد', 'قيود', 'يومية'],
  ),
];
