import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/approval_request.dart';
import '../../domain/repos/approvals_repo.dart';

part 'approvals_repo_actions_part.dart';
part 'approvals_repo_leave_helpers_part.dart';
part 'approvals_repo_counts_part.dart';
part 'approvals_repo_fetch_part.dart';
part 'approvals_repo_balance_helpers_part.dart';
part 'approvals_repo_helpers_part.dart';
part 'approvals_repo_session_part.dart';

class ApprovalsRepoImpl
    with
        _ApprovalsRepoSessionMixin,
        _ApprovalsRepoBalanceHelpersMixin,
        _ApprovalsRepoHelpersMixin,
        _ApprovalsRepoLeaveHelpersMixin,
        _ApprovalsRepoFetchMixin,
        _ApprovalsRepoCountsMixin,
        _ApprovalsRepoActionsMixin
    implements ApprovalsRepo {
  ApprovalsRepoImpl(this._client);

  final SupabaseClient _client;
}
