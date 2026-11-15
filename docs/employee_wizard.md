# Employee creation workspace

The employee creation route uses four steps: personal information, job, contract, and compensation. Login role/password and optional attendance identity remain in the final step. The existing creation, photo upload, account provisioning, and attendance identity workflow is preserved.

The personal step shows a responsive two-column grid and an optional JPG/PNG photo card (maximum 2 MB). Additional personal fields remain available in an expandable section. Validation opens that section when required gender is missing. Nationality is now passed to the existing employee creation repository.

Visited steps retain their widget state, including text edits, salary controllers, and the password, when navigating back. Only previously completed steps can be selected in the progress indicator. Contract end dates cannot precede start dates; probation must be a nonnegative integer.

If account provisioning or attendance linking fails after employee creation, the existing saved employee ID is retained for retry. Employee and compensation fields are locked during that retry; the account fields remain available. A retry does not create another employee.

Validation: `flutter test test/employee_wizard_design_test.dart test/employee_provisioning_test.dart` covers all four steps in Arabic/English at 320, 768, and 1350 logical pixels, retained edits, required-field validation, invalid contract dates, and provisioning retries using fake repositories.
