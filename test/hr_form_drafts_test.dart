import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_sys/features/hr_forms/data/hr_form_drafts_repo.dart';
import 'package:erp_sys/features/hr_forms/view/pages/hr_prototype_editor.dart';
import 'package:erp_sys/features/hr_forms/domain/models/hr_prototype_def.dart';
import 'package:erp_sys/features/employees/data/repos/hr_employees_repo.dart';
import 'hr_forms_workspace_test.dart' show app, employee, selectEmployee;

class MemoryDrafts implements HrFormDraftsRepo {
  int submissions = 0;
  bool failSubmit = false;
  @override
  Future<HrSavedDraft> submit(HrSavedDraft d) async {
    if (failSubmit) throw StateError('offline');
    submissions++;
    final submitted = HrSavedDraft(
      id: d.id,
      templateId: d.templateId,
      data: d.data,
      version: d.version + 1,
      updatedAt: DateTime(2026, 10, 12),
      employeeId: d.employeeId,
      status: 'pending',
      approverRole: 'manager',
      approvalId: 'a1',
      reference: 'HR-2026-000001',
    );
    rows[d.id] = submitted;
    return submitted;
  }

  final rows = <String, HrSavedDraft>{};
  bool fail = false;
  @override
  Future<HrSavedDraft> save({
    required String templateId,
    required Map<String, dynamic> data,
    String? employeeId,
    HrSavedDraft? previous,
  }) async {
    if (fail) throw StateError('offline');
    final saved = HrSavedDraft(
      id: previous?.id ?? 'd${rows.length + 1}',
      templateId: templateId,
      data: jsonDecode(jsonEncode(data)) as Map<String, dynamic>,
      employeeId: employeeId,
      version: (previous?.version ?? 0) + 1,
      updatedAt: DateTime.utc(2026, 10, 12),
    );
    rows[saved.id] = saved;
    return saved;
  }

  @override
  Future<List<HrSavedDraft>> list() async => rows.values.toList();
  @override
  Future<List<Map<String, dynamic>>> events(String id) async => [
    for (var v = rows[id]!.version; v > 0; v--)
      {
        'version': v,
        'action': v == 1 ? 'created' : 'saved',
        'created_at': '2026-10-12T12:00:00Z',
      },
  ];
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  test('Draft equality is stable across JSONB key ordering', () {
    expect(
      hrDraftFingerprint({
        'fields': {'a': '1', 'b': '2'},
        'checks': {'x': true},
      }),
      hrDraftFingerprint({
        'checks': {'x': true},
        'fields': {'b': '2', 'a': '1'},
      }),
    );
    expect(
      hrDraftFingerprint({
        'fields': {'a': '1'},
      }),
      isNot(
        hrDraftFingerprint({
          'fields': {'a': '2'},
        }),
      ),
    );
  });
  test(
    'Supabase save sends optimistic version and restores typed data',
    () async {
      Map<String, dynamic>? sent;
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/rest/v1/rpc/hr_save_form_draft');
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'id': 'd',
              'template_id': 'onboarding',
              'employee_id': 'e',
              'employee_name': 'Sample',
              'data': sent!['p_data'],
              'version': 3,
              'updated_at': '2026-10-12T12:00:00Z',
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final old = HrSavedDraft(
        id: 'd',
        templateId: 'onboarding',
        data: const {},
        version: 2,
        updatedAt: DateTime(2026),
      );
      final saved = await SupabaseHrFormDraftsRepo(client).save(
        templateId: 'onboarding',
        employeeId: 'e',
        previous: old,
        data: {
          'checks': {'documents': true},
          'fields': {'start': '2026/10/12'},
        },
      );
      expect(sent!['p_expected_version'], 2);
      expect(sent!['p_id'], 'd');
      expect(sent!['p_employee_id'], 'e');
      expect(saved.version, 3);
      expect((saved.data['checks'] as Map)['documents'], true);
    },
  );
  testWidgets('Acknowledgment draft restores employee and entered signatory', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1350, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = MemoryDrafts();
    await tester.pumpWidget(app(lang: 'en', draftsRepo: repo));
    await tester.pumpAndSettle();
    await selectEmployee(tester);
    final signature = find.widgetWithText(TextField, 'Signatory name');
    await tester.ensureVisible(signature);
    await tester.enterText(signature, 'Saved signer');
    await tester.pumpAndSettle();
    await tapKey(tester, 'hr-save-draft');
    expect(repo.rows['d1']!.employeeId, employee.id);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(lang: 'en', draftsRepo: repo));
    await tester.pumpAndSettle();
    await tapKey(tester, 'hr-draft-history');
    await tapKey(tester, 'resume-d1');
    expect(
      tester.widget<TextField>(signature).controller!.text,
      'Saved signer',
    );
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const ValueKey('hr-form-employee')),
          )
          .initialValue,
      employee.id,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Prototype resume restores employee, dates and checklist after loading',
    (tester) async {
      final template = findHrPrototype('onboarding')!;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HrPrototypeEditor(
              template: template,
              loadEmployees: () async => HrEmployeesData(employees: [employee]),
              initialData: {
                'employee_id': employee.id,
                'fields': {'start': '2026/10/20', 'owner': 'HR owner'},
                'checks': {'documents': true, 'equipment': false},
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byKey(const ValueKey('prototype-employee')),
            )
            .initialValue,
        employee.id,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('prototype-field-start')),
            )
            .controller!
            .text,
        '2026/10/20',
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Documents received'),
            )
            .value,
        true,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Partial prototype draft survives reopening and updates same record',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1350, 1300));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = MemoryDrafts();
      await tester.pumpWidget(app(lang: 'en', draftsRepo: repo));
      await tester.pumpAndSettle();
      await tapKey(tester, 'template-hiring-request');
      final field = find.byKey(const ValueKey('prototype-field-headcount'));
      await tester.enterText(field, '3');
      await tester.pumpAndSettle();
      await tapKey(tester, 'hr-save-draft');
      expect(repo.rows.length, 1);
      expect((repo.rows['d1']!.data['fields'] as Map)['headcount'], '3');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(app(lang: 'en', draftsRepo: repo));
      await tester.pumpAndSettle();
      await tapKey(tester, 'hr-draft-history');
      await tester.enterText(
        find.byKey(const ValueKey('draft-history-search')),
        'Hiring',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hiring request').last);
      await tester.pumpAndSettle();
      expect(find.text('Draft created'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'resume-d1');
      expect(tester.widget<TextFormField>(field).controller!.text, '3');
      await tester.enterText(field, '4');
      await tester.pumpAndSettle();
      await tapKey(tester, 'hr-save-draft');
      expect(repo.rows.length, 1);
      expect(repo.rows['d1']!.version, 2);
      expect((repo.rows['d1']!.data['fields'] as Map)['headcount'], '4');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Failed save retains edits and cancel prevents leaving dirty form',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1350, 1300));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = MemoryDrafts()..fail = true;
      await tester.pumpWidget(app(lang: 'en', draftsRepo: repo));
      await tester.pumpAndSettle();
      await tapKey(tester, 'template-hiring-request');
      final field = find.byKey(const ValueKey('prototype-field-headcount'));
      await tester.enterText(field, '5');
      await tester.pumpAndSettle();
      await tapKey(tester, 'hr-save-draft');
      expect(repo.rows, isEmpty);
      expect(tester.widget<TextFormField>(field).controller!.text, '5');
      await tapKey(tester, 'template-ack');
      expect(find.text('Unsaved changes'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(HrPrototypeEditor), findsOneWidget);
      expect(tester.widget<TextFormField>(field).controller!.text, '5');
      expect(tester.takeException(), isNull);
    },
  );
}
