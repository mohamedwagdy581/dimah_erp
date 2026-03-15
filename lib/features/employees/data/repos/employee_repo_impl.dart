import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/env.dart';
import '../../domain/models/employee.dart';
import '../../domain/models/employee_lookup.dart';
import '../../domain/models/employee_profile_details.dart';
import '../../domain/models/expiry_alert.dart';
import '../../domain/repos/employee_repo.dart';

part 'employee_repo_auth_part.dart';
part 'employee_repo_employee_lookup_part.dart';
part 'employee_repo_employees_list_part.dart';
part 'employee_repo_create_helpers_part.dart';
part 'employee_repo_create_payload_part.dart';
part 'employee_repo_create_fallback_part.dart';
part 'employee_repo_create_fallback_request_part.dart';
part 'employee_repo_employee_create_rpc_part.dart';
part 'employee_repo_employee_create_part.dart';
part 'employee_repo_expiry_alerts_helpers_part.dart';
part 'employee_repo_expiry_alerts_part.dart';
part 'employee_repo_expiry_settings_part.dart';
part 'employee_repo_profile_fetch_helpers_part.dart';
part 'employee_repo_profile_fetch_queries_part.dart';
part 'employee_repo_profile_fetch_part.dart';
part 'employee_repo_profile_update_part.dart';
part 'employee_repo_session_part.dart';
part 'employee_repo_versions_part.dart';

class EmployeesRepoImpl
    with
        _EmployeesRepoSessionMixin,
        _EmployeesRepoAuthMixin,
        _EmployeesRepoEmployeesListMixin,
        _EmployeesRepoEmployeeLookupMixin,
        _EmployeesRepoCreateHelpersMixin,
        _EmployeesRepoCreatePayloadMixin,
        _EmployeesRepoCreateFallbackMixin,
        _EmployeesRepoCreateFallbackRequestMixin,
        _EmployeesRepoEmployeeCreateRpcMixin,
        _EmployeesRepoEmployeeCreateMixin,
        _EmployeesRepoProfileFetchHelpersMixin,
        _EmployeesRepoProfileFetchQueriesMixin,
        _EmployeesRepoProfileFetchMixin,
        _EmployeesRepoProfileUpdateMixin,
        _EmployeesRepoExpirySettingsMixin,
        _EmployeesRepoExpiryAlertsHelpersMixin,
        _EmployeesRepoExpiryAlertsMixin,
        _EmployeesRepoVersionsMixin
    implements EmployeesRepo {
  EmployeesRepoImpl(this._client);

  final SupabaseClient _client;
}
