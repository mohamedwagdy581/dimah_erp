import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/attendance_import_record.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/repos/attendance_repo.dart';

part 'attendance_repo_actions_part.dart';
part 'attendance_repo_fetch_part.dart';
part 'attendance_repo_helpers_part.dart';
part 'attendance_repo_session_part.dart';

class AttendanceRepoImpl
    with
        _AttendanceRepoSessionMixin,
        _AttendanceRepoHelpersMixin,
        _AttendanceRepoFetchMixin,
        _AttendanceRepoActionsMixin
    implements AttendanceRepo {
  AttendanceRepoImpl(this._client);

  final SupabaseClient _client;
}
