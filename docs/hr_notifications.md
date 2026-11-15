# HR notifications

The HR notification route uses the purple shell and a bordered workspace with All/Unread counts, category badges, title and full description, local date/time, unread indicators and details actions. The table fills available space and retains a readable minimum width with horizontal and vertical scrollbars. The HR sidebar includes a direct link.

The feed uses existing approval requests and returned payroll runs. IDs and timestamps come from those records; unavailable timestamps display a dash. No sample events are inserted. Opening details records the item as read and offers the existing related route. This does not approve or modify the source request.

Read IDs persist in SharedPreferences separately for each tenant/user on the current device. They do not sync between devices. The shell bell count retains its existing meaning of pending work and is not the table unread count. No SQL migration is required. Existing employee, manager and finance notifications retain their current UI and behavior.

`flutter test test/hr_notifications_design_test.dart test/employee_notifications_test.dart` covers Arabic/English at 320/768/1440 pixels, access to details after horizontal scrolling, unread filters, persisted read IDs and user isolation, error retry, empty states and related-page navigation. The tests use local fixtures and mocked preferences, with no live database writes. Set `EXPORT_NOTIFICATIONS=true` to export a visual preview on Windows with the test font paths.
