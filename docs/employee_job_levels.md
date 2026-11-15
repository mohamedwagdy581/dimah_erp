# Employee role and job level

Login roles determine access. Job level (`junior`, `mid`, `senior`, or unspecified)
describes experience and never grants permissions. HR/admin set it from the
employee profile; finance sees it in team cards and payroll assignment.

Install in Supabase SQL Editor, one entire file at a time:

1. `supabase/install_employee_job_levels.sql`
2. `supabase/install_finance_employee_assignment.sql`
3. `supabase/install_finance_team_overview.sql` (updated to return job level)
4. `supabase/repair_mahrous_employee_role.sql`

The targeted repair validates the main finance account, the existing Mahrous
Auth/application link and active EMP-0013. It preserves account IDs, passwords,
employee history and tasks. It changes Mahrous to `employee`, sets `senior` and
sets his reporting manager to the employee linked to `finance@dimahmusic.com`.
It stops if he still manages employees/departments, so those reporting lines can
be reviewed rather than changed silently. Sign out and sign in after repair.

Finance assignment accepts an active employee/accountant account in the
authenticated finance manager's direct team or managed department. It validates
the approved run and task ownership, then updates task and run in one transaction.
The task appears in the assignee's ordinary employee task list. This grants no
access to other employees' payroll, finance dashboards or approval actions.
The bank transfer takes place outside the app. Completing an ordinary task does
not automatically mark the payroll as paid.

SQL has to be installed on the project; local Flutter tests mock the RPC boundary
and do not validate a live database deployment.
