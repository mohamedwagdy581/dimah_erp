# HR departments and job titles

HR uses one sidebar entry, with department and job-title tabs. Existing department
and job-title URLs continue to work; administrator pages retain their existing
views. Search matches name/code across the loaded company list, and the status
filter includes both active and inactive records. Lists are fetched in pages of
500 with stable sorting, then displayed eight records per page.

The inline form preserves descriptions, department-manager assignment, job-title
department assignment, level and status during edits. New records may be created
inactive. Save errors retain the entered values; a successful save clears the
form and reloads the list. Existing automatic department-manager assignment is
available through the wand icon in the department-list header.

No schema migration is required. Repository writes still use the current tenant.
The job-title count query now also filters by tenant, matching the list query.

Validation: `flutter test test/hr_organization_test.dart` covers Arabic/English
at 320/768/1440 pixels, search beyond the first page, department-manager edits,
inactive creation, failed saves and preservation of all job-title fields.
Optional Windows preview: `--dart-define=EXPORT_ORGANIZATION_PREVIEW=true`,
saved to `build/hr_organization_preview.png`.
