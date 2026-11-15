# HR employee documents

The HR documents route shows employee cards beside an inline add/edit form. Cards display the employee photo (or initials), name, job title, employee number, document type, issue date, expiry date and actions.

Filters apply to all company documents before employee-card pagination: employee, document type, expiry status and inclusive expiry-date range. Missing expiry dates remain visible unless a date range is selected. Existing `expiring_soon` and `no_expiry` links remain supported. "Soon" means today through the next 30 calendar days.

Select an employee, choose a document type, set dates as applicable, click the attachment area and save after upload completes. PDF, JPG/JPEG, PNG, DOC and DOCX use the existing `employee_docs` storage bucket and company-scoped repository. Dates remain optional. The attachment area opens a file picker; drag-and-drop is not implemented.

Actions open a document, save a local copy, edit metadata or delete after confirmation. Editing retains the existing attachment and dates. A failed save preserves the form for retry. Contract-renewal links prefill the inline form. This change requires no database installation.

Validation: `flutter test test/hr_employee_docs_design_test.dart`. Tests cover Arabic/English at 320, 768 and 1350 pixels, required fields, update failures/retry, legacy expiry links and confirmed/cancelled deletion. Add `--dart-define=EXPORT_HR_DOCS=true` to render a fixture preview to `build/hr_employee_docs_preview.png` on Windows.
