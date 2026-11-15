# Expiry alerts

The HR expiry screen follows the purple portal theme. It shows expiry/type filters and shortcuts, expired and upcoming counts, an employee/document table and an inline settings card. The existing Government Alerts tab and its actions remain available.

The main days setting accepts integers from 1 to 365 and applies the selected warning period to contracts, residency, insurance and employee documents. Existing settings are displayed on load. The advanced settings link retains individual warning periods by type. Save failures keep the entered value for retry.

Expiry status is separate from follow-up state: active, snoozed and handled alerts can be viewed without conflating a handled alert with a renewed document. Summaries follow the selected type and follow-up scope. Expired records have a red badge; upcoming records use orange. Expired days display zero; actual expiry dates are retained. The near-expiry count uses each type's configured warning period, not a fixed 30-day threshold.

Expired rows offer a direct renewal action; upcoming rows open the employee profile. The overflow menu preserves open profile/documents/current attachment, renew, snooze for seven days, mark handled and restore. Contract renewal opens the employee contract editor; document renewal preselects the employee, type and dates in the employee documents form.

Validation: `flutter test test/hr_expiry_alerts_design_test.dart`. Arabic and English layouts are tested at 320, 768 and 1350 pixels, alongside settings validation/retry, filters, handled records and renewal routing. Add `--dart-define=EXPORT_HR_EXPIRY=true` for the fixture preview `build/hr_expiry_alerts_preview.png`.
