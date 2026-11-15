import 'dart:convert';
import 'package:erp_sys/core/session/api_session_repo.dart';
import 'package:erp_sys/core/session/session_cubit.dart';
import 'package:erp_sys/core/session/session_repo.dart';
import 'package:erp_sys/core/session/app_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final profile = {
    'user': {
      'id': 'user-a',
      'email': 'a@example.test',
      'role': 'finance_manager',
      'tenant_id': 'tenant-a',
      'employee_id': 'employee-a',
      'is_active': true,
    },
  };
  ApiSessionRepo repo(
    http.Client client, {
    String? Function()? uid,
    String? Function()? token,
    Future<void> Function()? refresh,
    Future<void> Function()? signOut,
  }) => ApiSessionRepo(
    baseUrl: 'https://api.dimahmusic.com',
    client: client,
    userId: uid ?? () => 'user-a',
    accessToken: token ?? () => 'session-token',
    refresh: refresh ?? () async {},
    signOut: signOut ?? () async {},
  );
  test(
    'Current-user request sends the session token and uses the server role',
    () async {
      final user = await repo(
        MockClient((request) async {
          expect(request.url.toString(), 'https://api.dimahmusic.com/v1/me');
          expect(request.headers['Authorization'], 'Bearer session-token');
          expect(request.followRedirects, false);
          return http.Response(jsonEncode(profile), 200);
        }),
      ).getCurrentAppUser();
      expect(user!.role, 'finance_manager');
      expect(user.tenantId, 'tenant-a');
    },
  );
  test('No login means no API request', () async {
    expect(
      await repo(
        MockClient((_) async => throw StateError('Unexpected call')),
        uid: () => null,
      ).getCurrentAppUser(),
      isNull,
    );
  });
  test('401 refreshes once and retries with the new token', () async {
    var token = 'old';
    var calls = 0;
    var refreshes = 0;
    final user = await repo(
      MockClient((request) async {
        calls++;
        expect(
          request.headers['Authorization'],
          calls == 1 ? 'Bearer old' : 'Bearer new',
        );
        return calls == 1
            ? http.Response('{"error":"invalid_or_expired_token"}', 401)
            : http.Response(jsonEncode(profile), 200);
      }),
      token: () => token,
      refresh: () async {
        refreshes++;
        token = 'new';
      },
    ).getCurrentAppUser();
    expect(user, isNotNull);
    expect(calls, 2);
    expect(refreshes, 1);
  });
  test('Repeated 401 stops after one retry', () async {
    var calls = 0;
    await expectLater(
      repo(
        MockClient((_) async {
          calls++;
          return http.Response('{}', 401);
        }),
      ).getCurrentAppUser(),
      throwsA(isA<ApiSessionException>()),
    );
    expect(calls, 2);
  });
  test('Inactive ERP account signs out', () async {
    var signedOut = false;
    expect(
      await repo(
        MockClient(
          (_) async =>
              http.Response('{"error":"active_erp_account_required"}', 403),
        ),
        signOut: () async {
          signedOut = true;
        },
      ).getCurrentAppUser(),
      isNull,
    );
    expect(signedOut, true);
  });
  test('API outage preserves login and surfaces an error', () async {
    var signedOut = false;
    await expectLater(
      repo(
        MockClient((_) async => http.Response('{}', 502)),
        signOut: () async {
          signedOut = true;
        },
      ).getCurrentAppUser(),
      throwsA(isA<ApiSessionException>()),
    );
    expect(signedOut, false);
  });
  test('Wrong identity and malformed profiles are rejected', () async {
    for (final body in [
      'not-json',
      '{"user":{}}',
      jsonEncode({
        'user': {...profile['user']!, 'id': 'another'},
      }),
    ]) {
      await expectLater(
        repo(
          MockClient((_) async => http.Response(body, 200)),
        ).getCurrentAppUser(),
        throwsA(isA<ApiSessionException>()),
      );
    }
  });
  test('A response from the previous login is discarded', () async {
    String? uid = 'user-a';
    expect(
      await repo(
        MockClient((_) async {
          uid = 'user-b';
          return http.Response(jsonEncode(profile), 200);
        }),
        uid: () => uid,
      ).getCurrentAppUser(),
      isNull,
    );
  });
  test('Session can retry after a connection failure', () async {
    final source = _RetryRepo();
    final cubit = SessionCubit(source);
    await cubit.load();
    expect(cubit.state, isA<SessionFailed>());
    source.fail = false;
    await cubit.load();
    expect(cubit.state, isA<SessionReady>());
    await cubit.close();
  });
}

class _RetryRepo implements SessionRepo {
  bool fail = true;
  @override
  Future<AppUser?> getCurrentAppUser() async {
    if (fail) throw const ApiSessionException();
    return const AppUser(
      id: 'user-a',
      email: 'a@example.test',
      role: 'employee',
      tenantId: 'tenant-a',
      employeeId: null,
    );
  }
}
