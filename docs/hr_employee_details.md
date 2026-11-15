# HR employee details

The employee profile keeps the existing report export, editing, attendance identity,
contract creation, compensation version creation, settlement creation and file-opening
callbacks. A summary shows the employee photo (or initials), employee number,
employment status, job title, department, hire date and direct manager.

Tabs contain all existing profile data: personal details (including insurance,
residency, passport and education), employment/contact details, contracts,
compensation and banking, documents, leave balances, and settlements.
Contracts open initially, including when following a contract-renewal link.
Dialog saves refresh the profile without resetting the selected tab.

The direct manager is read from the employee's existing `manager_id`, with the
same tenant filter as the employee. Missing manager/employee numbers show no
invented values. No database migration is needed.

The contract expiry panel calculates calendar days from the stored expiry date.
It distinguishes missing dates, expired contracts and future start dates. This is
a visual indicator, not a new background notification system. History row numbers
describe display order; no persisted version identifiers are invented.

Validation: `flutter test test/hr_employee_details_test.dart` covers Arabic and
English at 320/768/1440 pixels, edit/add/open callbacks, read-only controls and
retention of insurance/education fields. On Windows, optionally generate a visual
preview with `--dart-define=EXPORT_HR_DETAILS_PREVIEW=true`; output is
`build/hr_employee_details_preview.png`.
