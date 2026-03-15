import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

part 'my_tasks_repo_helpers_part.dart';
part 'my_tasks_repo_load_part.dart';
part 'my_tasks_repo_update_part.dart';
part 'my_tasks_repo_review_part.dart';
part 'my_tasks_repo_attachments_part.dart';
part 'my_tasks_repo_events_part.dart';
part 'my_tasks_repo_time_logs_part.dart';
part 'my_tasks_repo_timer_part.dart';

class MyTasksRepo
    with
        _MyTasksRepoHelpersMixin,
        _MyTasksRepoEventsMixin,
        _MyTasksRepoLoadMixin,
        _MyTasksRepoUpdateMixin,
        _MyTasksRepoReviewMixin,
        _MyTasksRepoAttachmentsMixin,
        _MyTasksRepoTimeLogsMixin,
        _MyTasksRepoTimerMixin {
  MyTasksRepo(this._client);

  final SupabaseClient _client;
}
