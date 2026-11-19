import 'package:erp_sys/features/accounting/view/accounting_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('accountingPanel can host a SwitchListTile without assertions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: accountingPanel(
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Account status'),
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Account status'), findsOneWidget);
  });
}
