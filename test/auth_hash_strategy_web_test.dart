@TestOn('browser')
library;

import 'package:erp_sys/core/auth/auth_url_strategy_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

class _Location implements PlatformLocation {
  _Location(this.fragment);
  final String fragment;
  @override
  String get hash => '#$fragment';
  @override
  String get pathname => '/';
  @override
  String get search => '';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'Browser hash strategy returns valid routes for Auth success and error',
    () {
      expect(
        AuthHashUrlStrategy(
          _Location('error=access_denied&error_code=otp_expired'),
        ).getPath(),
        '/',
      );
      expect(
        AuthHashUrlStrategy(
          _Location('access_token=fixture&type=recovery'),
        ).getPath(),
        '/',
      );
      expect(
        AuthHashUrlStrategy(_Location('/my?tab=tasks')).getPath(),
        '/my?tab=tasks',
      );
    },
  );
}
