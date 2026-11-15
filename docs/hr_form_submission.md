# Leave and Early Exit request workflow

Run `supabase/install_hr_form_submission.sql` once after the draft installation. Existing approval workflow, leave requests, leave balances, and leave balance history tables must already be installed. This migration does not submit or approve existing drafts.

There are now 15 forms: the original 14 plus Early Exit Permission. Submission is enabled for Leave Request and Early Exit only. Other forms retain draft/PDF functionality.

## HR workflow

1. Select the employee and complete the form. Early Exit requires a date, departure time, normal shift end and reason; the departure must be earlier on the same day. Leave requires valid start/end dates within one calendar year.
2. Click **Submit for approval** and confirm. The app saves current edits first. Submission atomically creates one linked approval, a request number, a history entry and (for leave) a pending leave record. Retrying the same submitted draft cannot create duplicates.
3. The assigned active direct manager reviews first, including Finance Manager accounts acting as a direct manager. Missing direct links fall back to the department manager. If no eligible manager account exists, the request starts with HR; if there is no HR reviewer, it starts with Admin. An eligible Admin account is required.
4. Manager approval forwards to HR (or Admin if HR is unavailable). HR forwards to Admin. Final Admin approval completes the request. Reviewers cannot approve their own employee request. Rejection requires a reason.
5. Open **Drafts and request history** to filter by status, inspect rejection reasons and expand the review timeline. Submitted, approved and rejected copies are read-only. **New draft** starts a separate form.

The normal Approvals screen is used for reviewer decisions. Server functions enforce tenant and reviewer identity checks; workflow-linked approvals and leaves cannot be edited directly by authenticated clients.

## Leave balances and attendance

Annual eligibility follows the existing app's 11-month rule and year policy. Available leave is checked at submission and rechecked under a balance-row lock on final approval. Only final approval deducts annual/sick/other days and writes balance history. Unpaid leave does not deduct these balances. Pending and rejected requests do not deduct days. Cross-year requests must be split into separate forms.

Early Exit records permission only. It does not invent an attendance check-out or change biometric records.

Employee self-service, withdrawal/cancellation, amendment of approved requests and final signed PDF documents are later stages. Current printable forms retain the existing prototype layout.

## Verification

Flutter tests cover invalid inputs, submission success/failure, preserved drafts, request-number/status decoding, read-only forms, and starting another draft. Existing form and approval UI/routing checks are retained.

`supabase/test_hr_form_submission.sql` is an optional database integration check for a disposable test transaction. It impersonates existing eligible reviewers and rolls back its temporary rows. Install and run it in Supabase SQL Editor to validate the server workflow. This repository work has not executed the migration or database test against your hosted project.
