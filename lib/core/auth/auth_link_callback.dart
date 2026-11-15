/// Only callback metadata is retained. Tokens and descriptions are never stored.
class AuthLinkCallback {
  const AuthLinkCallback({
    this.isCallback = false,
    this.isRecovery = false,
    this.implicit = false,
    this.failed = false,
    this.expired = false,
  });
  final bool isCallback;
  final bool isRecovery;
  final bool implicit;
  final bool failed;
  final bool expired;

  factory AuthLinkCallback.fromUri(Uri uri) {
    Map<String, String> fragment = {};
    try {
      if (!uri.fragment.startsWith('/')) {
        fragment = Uri.splitQueryString(uri.fragment);
      }
    } on FormatException {
      /* A malformed fragment must not crash startup. */
    }
    final params = {...uri.queryParameters, ...fragment};
    final implicit = params.containsKey('access_token');
    final failed =
        params.containsKey('error') || params.containsKey('error_code');
    final callback =
        implicit ||
        failed ||
        params.containsKey('code') ||
        params['type'] == 'recovery';
    return AuthLinkCallback(
      isCallback: callback,
      implicit: implicit,
      failed: failed,
      expired: params['error_code'] == 'otp_expired',
      isRecovery: !failed && params['type'] == 'recovery',
    );
  }
}

class AuthLinkStartup {
  static AuthLinkCallback? callback;
}

/// Hash routing must not interpret Auth's fragment as a page path.
String authSafeHashPath(String path) {
  if (path.startsWith('/')) return path;
  final info = AuthLinkCallback.fromUri(Uri(fragment: path));
  return info.isCallback ? '/' : path;
}
