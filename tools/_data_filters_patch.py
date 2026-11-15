import pathlib, json, difflib
mapping = {
    'employees_table_section.dart': 'state.search.trim().isNotEmpty || state.status != null',
    'departments_table_section.dart': 'state.search.trim().isNotEmpty || state.isActive != null',
    'job_titles_table_section.dart': 'state.search.trim().isNotEmpty || state.isActive != null',
    'payroll_table_section.dart': 'state.status != null || state.startDate != null || state.endDate != null',
    'leaves_table_section.dart': 'state.search.trim().isNotEmpty || state.status != null || state.type != null || state.startDate != null || state.endDate != null',
    'attendance_table_section.dart': 'state.search.trim().isNotEmpty || state.status != null || state.date != null',
}
replacements = {
    'employee_attendance_test.dart': [('Unable to load attendance', 'Unable to load data')],
    'employee_notifications_test.dart': [('Could not load notifications', 'Unable to load data')],
    'employee_request_history_test.dart': [('Unable to load request history', 'Unable to load data'), ('No requests match these filters', 'No matching results')],
    'employee_tasks_test.dart': [('إعادة ضبط الفلاتر', 'مسح الفلاتر'), ("    await tester.tap(find.text('إعادة المحاولة'));", "    await tester.ensureVisible(find.text('إعادة المحاولة'));\n    await tester.pumpAndSettle();\n    await tester.tap(find.text('إعادة المحاولة'));")],
    'manager_attendance_test.dart': [('تعذر تحميل حضور الفريق', 'تعذّر تحميل البيانات')],
    'hr_settlements_design_test.dart': [('تعذّر تحميل المخالصات', 'تعذّر تحميل البيانات')],
    'widget_test.dart': [('تعذّر تحميل لوحة الموظف', 'تعذّر تحميل البيانات')],
    'user_management_test.dart': [('لا يوجد مستخدمون مطابقون', 'لا توجد نتائج مطابقة')],
}
patch = '*** Begin Patch\n'; files = []
for path in [*pathlib.Path('lib/features').rglob('*.dart'), *pathlib.Path('test').glob('*.dart')]:
    s = original = path.read_text(encoding='utf-8')
    if path.name in mapping:
        s = s.replace('error: state.error,', 'error: state.error,\n                  empty: state.items.isEmpty,\n                  filtered: ' + mapping[path.name] + ',\n                  onClear: cubit.resetFilters,', 1)
    if path.name in replacements:
        for a, b in replacements[path.name]: s = s.replace(a, b)
    if s != original:
        diff = list(difflib.unified_diff(original.splitlines(), s.splitlines(), n=3))[2:]
        patch += '*** Update File: ' + str(path).replace('\\', '/') + '\n'
        patch += '\n'.join('@@' if l.startswith('@@') else l for l in diff) + '\n'
        files.append(str(path))
patch += '*** End Patch'
print(json.dumps({'patch': patch, 'files': files}))
