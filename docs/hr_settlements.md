# HR employee settlements

The settlements route now displays an employee settlement editor beside a record-level history table. The employee selector loads all company employees, including inactive employees; the table displays individual settlements rather than only each employee's latest summary. Both queries page in batches of 500 with stable ordering.

The editor supports final, partial, and other settlements, settlement date, gross amount, deductions, notes, and an optional PDF/JPG/PNG attachment up to 5 MB. Final settlements also expose the final working date and explain the employee status change. The table shows the net amount; the details action preserves access to gross, deductions, dates, full notes, and the attachment. Other actions open the attachment or employee profile.

The panels stack below 1000 logical pixels. The table retains every column at a minimum readable width, with persistent horizontal and vertical scrollbars. Actions are the final column. Search and pagination operate on the loaded records.

## Installation

Run `supabase/install_hr_settlements.sql` once in the Supabase SQL editor, then restart the Flutter application. The script is idempotent and preserves existing rows. It adds settlement type and attachment metadata, a private 5 MB attachment bucket, tenant-scoped policies, and the `hr_save_employee_settlement` RPC. The script has not been applied to the live database by this change.

The new RPC checks an active HR/admin account and employee tenant, saves the settlement and final employee status change in one transaction, and supports retrying the same request ID with unchanged values. Partial/other settlements do not deactivate the employee. The existing employee-profile settlement dialog still creates a final settlement through its existing repository method.

Attachments use a tenant/employee/request path in the private bucket. Viewing generates a signed link valid for five minutes. Upload occurs before saving; if saving fails, the form and request ID remain available for retry. Uploaded objects are retained during failure because a network error may occur after the database transaction has committed.

## Validation

If an attachment upload returns Storage 403 / "new row violates row-level security policy", run `supabase/repair_hr_settlement_storage.sql` in the SQL editor, then retry the existing form without restarting the application. This repair preserves settlement rows and stored files. Both the repair and installer use a restricted security-definer membership helper, with explicitly qualified object names, so the storage policies do not depend on users/employees read policies or ambiguous column names. Access still requires an active HR/admin account, a matching tenant and employee, and the settlement UUID file path. Upload uses upsert, requiring insert, select and update policies. The repair has not been applied to the live project by this change.

`flutter test test/hr_settlements_design_test.dart test/hr_settlements_repo_test.dart` validates Arabic/English layouts at 320/768/1350 pixels, access to row actions, retained drafts on failure, deductions, attachment validation, legacy records, loading retries, 501-row pagination, tenant filters, RPC payloads, and upload-before-save ordering against local fixtures. These tests do not execute the migration against PostgreSQL or contact the live Supabase project.
