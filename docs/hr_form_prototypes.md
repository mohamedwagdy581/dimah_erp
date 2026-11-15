# HR form library

The next workflow stage adds Early Exit Permission, bringing the library to 15 forms. Leave Request and Early Exit can now be submitted after installing `install_hr_form_submission.sql`; see `docs/hr_form_submission.md` for routing, status tracking and installation.

Open HR **Forms → Forms library** to choose among 14 forms: the existing leave request and acknowledgment plus 12 new prototypes.

The new forms cover hiring, onboarding, probation review, employee information updates, transfer/promotion, salary adjustments, training, business trips, leave changes, overtime authorization, performance appraisal, and resignation/exit interviews.

Select an active employee to populate their identity, department and job title. Hiring requests allow no employee selection. Complete the required fields before previewing, printing or exporting a PDF. Printouts include the company logo and blank signature lines.

These are fillable prototypes. They do not update employee records, salaries, attendance, or approval requests.

## Draft saving and history

Run `supabase/install_hr_form_drafts.sql` once in Supabase SQL Editor to enable persistent saving. Restart the app afterwards. PDF preview/export remains available without this installation.

Use **Save draft** in the workspace before closing the page. Incomplete forms can be saved. **Drafts and save history** lists your own account's drafts, with search, last saved time, version, and a collapsible save history (latest 100 entries). **Resume** restores the selected employee, typed fields, dates, and checklists in the same workspace. **New draft** creates a fresh form; it does not delete saved drafts.

Updates use an expected version so another session cannot silently overwrite your saved work. On a conflict, reopen the latest version from history. Failed saves retain current inputs. Switching forms or opening another draft prompts when changes have not been saved. Closing the app directly does not autosave: click Save draft first.

Storage is restricted server-side to the owning active HR/Admin account in its tenant. Employees referenced in drafts must belong to the same tenant. Direct client writes are disabled; an authorized SQL function atomically saves the draft and a history entry. History currently contains drafts only; submission and approval workflows will be added separately.

Validation: Flutter widget tests cover save/reopen, update without duplication, incomplete drafts, retained inputs on failure, checklist/date restoration, unsaved-change prompts, and history expansion. A mocked Supabase client checks RPC version parameters. The migration still needs to be installed and verified against your Supabase project.
