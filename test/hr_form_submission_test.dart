import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erp_sys/features/hr_forms/domain/models/hr_form_submission.dart';
import 'package:erp_sys/features/hr_forms/data/hr_form_drafts_repo.dart';
import 'package:erp_sys/features/hr_forms/view/pages/hr_prototype_editor.dart';
import 'hr_form_drafts_test.dart' show MemoryDrafts, tapKey;
import 'hr_forms_workspace_test.dart' show app, employee;

Map<String, dynamic> earlyData() => {
  'employee_id': employee.id,
  'fields': {
    'date': '2026/10/12',
    'departure': '14:00',
    'shiftEnd': '17:00',
    'reason': 'Personal appointment',
  },
  'checks': {},
};
void main() {
  test('Submission validates dates, employee and early-exit times', () {
    expect(hrFormSubmissionError('early-exit', earlyData(), false), isNull);
    final invalid = earlyData();
    (invalid['fields'] as Map)['departure'] = '18:00';
    expect(
      hrFormSubmissionError('early-exit', invalid, false),
      contains('before'),
    );
    expect(
      hrFormSubmissionError('early-exit', {'fields': {}}, false),
      contains('employee'),
    );
    expect(
      hrFormSubmissionError('leave-application-prototype', {
        'employee_id': 'e',
        'from': '2026-12-31',
        'to': '2027-01-01',
      }, false),
      contains('cross-year'),
    );
    expect(
      hrFormSubmissionError('leave-application-prototype', {
        'employee_id': 'e',
        'from': '2026-10-12',
        'to': '2026-10-10',
      }, false),
      contains('after'),
    );
  });
  test('Submit RPC sends saved version and decodes workflow status', () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/rest/v1/rpc/hr_submit_form_draft');
        expect(jsonDecode(request.body), {
          'p_id': 'd1',
          'p_expected_version': 2,
        });
        return http.Response(
          jsonEncode({
            'id': 'd1',
            'template_id': 'early-exit',
            'data': earlyData(),
            'employee_id': employee.id,
            'version': 3,
            'updated_at': '2026-10-12T12:00:00Z',
            'status': 'pending',
            'approval_id': 'a1',
            'reference': 'HR-2026-000001',
            'current_approver_role': 'finance_manager',
          }),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    final submitted = await SupabaseHrFormDraftsRepo(client).submit(
      HrSavedDraft(
        id: 'd1',
        templateId: 'early-exit',
        data: earlyData(),
        version: 2,
        updatedAt: DateTime(2026),
      ),
    );
    expect(submitted.status, 'pending');
    expect(submitted.approverRole, 'finance_manager');
    expect(submitted.approvalId, 'a1');
  });
  for (final fail in [false, true]) {
    testWidgets(
      'Early Exit submit failure=$fail preserves draft and locks only successful requests',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1350, 1300));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repo = MemoryDrafts()..failSubmit = fail;
        repo.rows['d1'] = HrSavedDraft(
          id: 'd1',
          templateId: 'early-exit',
          employeeId: employee.id,
          data: earlyData(),
          version: 1,
          updatedAt: DateTime(2026),
        );
        await tester.pumpWidget(app(lang: 'en', draftsRepo: repo));
        await tester.pumpAndSettle();
        await tapKey(tester, 'hr-draft-history');
        await tapKey(tester, 'resume-d1');
        // Avoid rasterization in this workflow test; PDF generation is tested separately.
        tester
            .widget<HrPrototypeEditor>(find.byType(HrPrototypeEditor))
            .onPreview!(null);
        await tapKey(tester, 'hr-submit-form');
        expect(find.text('Confirm submission'), findsOneWidget);
        await tester.tap(find.text('Confirm submission'));
        await tester.pumpAndSettle();
        expect(repo.submissions, fail ? 0 : 1);
        expect(repo.rows['d1']!.status, fail ? 'draft' : 'pending');
        expect(
          tester
              .widget<FilledButton>(find.byKey(const ValueKey('hr-save-draft')))
              .onPressed,
          fail ? isNotNull : isNull,
        );
        expect(
          tester
              .widget<HrPrototypeEditor>(find.byType(HrPrototypeEditor))
              .readOnly,
          !fail,
        );
        expect(tester.takeException(), isNull);
        if (!fail) {
          await tapKey(tester, 'hr-new-draft');
          expect(
            tester
                .widget<HrPrototypeEditor>(find.byType(HrPrototypeEditor))
                .readOnly,
            false,
          );
          expect(repo.rows['d1']!.status, 'pending');
        }
      },
    );
  }
}
