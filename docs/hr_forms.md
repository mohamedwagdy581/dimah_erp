# HR forms workspace

The HR forms route shows the template list, employee form editor, and PDF preview in one workspace. Below 1050 logical pixels, the panels stack vertically so all fields and actions remain accessible.

The employee selector uses the existing HR employee repository, including employee number, department, and job title. Selecting an employee fills these values and the signatory name. Existing detailed acknowledgment and leave editors remain accessible through the detailed-form link.

The acknowledgment template allows editing the statement, signatory, date, and acknowledgment checkbox. The checkbox starts unchecked. Preparing or exporting a form does not record employee consent in the database.

The leave template includes leave type, start/end dates, inclusive duration, notes, substitute, address, and contact information. Export requires both dates. Preparing this PDF does not submit a leave request or alter leave balances.

Preview and export generate an A4 PDF from the current values with the existing Arabic-capable font support and company logo. Export uses a native save dialog; expanded preview uses the existing PDF preview service. No database migration or new runtime dependency is required.

Validation: `flutter test test/hr_forms_workspace_test.dart` covers Arabic and English layouts at 320, 768, and 1350 logical pixels, employee selection, template switching, export validation, current edited values, and real Arabic/English PDF generation.
