import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/leave_balance.dart';
import '../../domain/models/leave_request.dart';
import '../../domain/repos/leaves_repo.dart';

part 'leaves_repo_create_part.dart';
part 'leaves_repo_resubmit_part.dart';
part 'leaves_repo_balances_part.dart';
part 'leaves_repo_fetch_part.dart';
part 'leaves_repo_helpers_part.dart';
part 'leaves_repo_session_part.dart';

class LeavesRepoImpl
    with
        _LeavesRepoSessionMixin,
        _LeavesRepoBalancesMixin,
        _LeavesRepoHelpersMixin,
        _LeavesRepoFetchMixin,
        _LeavesRepoCreateMixin,
        _LeavesRepoResubmitMixin
    implements LeavesRepo {
  LeavesRepoImpl(this._client);

  final SupabaseClient _client;
}
