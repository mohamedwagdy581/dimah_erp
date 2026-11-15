import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp_sys/core/ui/app_theme.dart';
import 'package:erp_sys/core/ui/employee_theme.dart';
import 'package:erp_sys/features/employees/domain/models/employee_profile_details.dart';
import 'package:erp_sys/features/employees/view/widgets/employee_profile/employee_profile_documents.dart';
import 'package:erp_sys/features/employees/view/widgets/employee_profile/employee_profile_leave_section.dart';
import 'package:erp_sys/features/employees/view/widgets/employee_profile/employee_profile_leave_balances.dart';
import 'package:erp_sys/features/leaves/domain/models/leave_balance.dart';
import 'package:erp_sys/l10n/app_localizations.dart';

final docs = [
  EmployeeProfileDocument(
    id: 'expired',
    docType: 'contract',
    fileUrl: 'https://example.test/contract.pdf',
    expiresAt: DateTime(2026, 10, 5),
  ),
  EmployeeProfileDocument(
    id: 'soon',
    docType: 'passport',
    fileUrl: '',
    expiresAt: DateTime(2026, 10, 24),
  ),
  EmployeeProfileDocument(
    id: 'valid',
    docType: 'id_card',
    fileUrl: 'https://example.test/id.pdf',
    expiresAt: DateTime(2027, 1, 1),
  ),
  const EmployeeProfileDocument(
    id: 'unknown',
    docType: 'bank_iban_certificate',
    fileUrl: 'https://example.test/iban.pdf',
  ),
];
const balances = [
  LeaveBalance(type: 'annual', entitlement: 21, used: 2.5),
  LeaveBalance(type: 'sick', entitlement: 10, used: 12),
  LeaveBalance(type: 'other', entitlement: 0, used: 0),
];
Widget app(Widget view, String locale) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: EmployeeTheme.from(AppTheme.light()),
  home: Scaffold(
    body: ListView(padding: const EdgeInsets.all(16), children: [view]),
  ),
);
void main() {
  for (final lang in ['ar', 'en']) {
    for (final width in [320.0, 768.0, 1440.0]) {
      testWidgets(
        'Documents and leave $lang $width retain values and file actions',
        (tester) async {
          tester.view.physicalSize = Size(width, 1700);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final opened = <String>[];
          await tester.pumpWidget(
            app(
              EmployeeProfileDocuments(
                documents: docs,
                onOpenUrl: opened.add,
                today: DateTime(2026, 10, 6),
              ),
              lang,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.text(lang == 'ar' ? 'منتهية' : 'Expired'),
            findsOneWidget,
          );
          expect(
            find.text(lang == 'ar' ? 'تنتهي قريبًا' : 'Expiring soon'),
            findsOneWidget,
          );
          expect(
            find.text(
              lang == 'ar' ? 'صلاحية غير محددة' : 'Expiry not specified',
            ),
            findsOneWidget,
          );
          expect(
            tester
                .widget<OutlinedButton>(
                  find.byKey(const ValueKey('profile-document-soon')),
                )
                .onPressed,
            isNull,
          );
          final open = find.byKey(const ValueKey('profile-document-expired'));
          await tester.ensureVisible(open);
          await tester.pumpAndSettle();
          await tester.tap(open);
          expect(opened, ['https://example.test/contract.pdf']);
          await tester.pumpWidget(
            app(const EmployeeProfileLeaveBalances(balances: balances), lang),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('18.5'), findsOneWidget);
          expect(find.text('-2'), findsOneWidget);
        },
      );
    }
  }
  testWidgets(
    'Leave eligibility and empty balances use injected load without device/database',
    (tester) async {
      const p = EmployeeProfileDetails(
        id: 'e',
        fullName: 'Employee',
        email: '',
        phone: '',
        status: 'active',
      );
      await tester.pumpWidget(
        app(
          EmployeeProfileLeaveSection(
            profile: p,
            balancesFuture: Future.value([]),
          ),
          'ar',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('أضف تاريخ التعيين لعرض موعد استحقاق الإجازة السنوية.'),
        findsOneWidget,
      );
      expect(
        find.text('لا توجد أرصدة إجازات مسجلة لهذا العام.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
