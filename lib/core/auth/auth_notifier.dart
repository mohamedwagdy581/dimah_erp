import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_link_callback.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier({
    Stream<AuthState>? authChanges,
    bool Function()? sessionExists,
    Uri? initialUri,
  }) : _sessionExists =
           sessionExists ??
           (() => Supabase.instance.client.auth.currentSession != null) {
    final callback = initialUri != null
        ? AuthLinkCallback.fromUri(initialUri)
        : AuthLinkStartup.callback ?? AuthLinkCallback.fromUri(Uri.base);
    _passwordRecovery = callback.isRecovery;
    _linkFailed = callback.failed;
    _linkExpired = callback.expired;
    _sub = (authChanges ?? Supabase.instance.client.auth.onAuthStateChange)
        .listen(
          (state) {
            if (state.event == AuthChangeEvent.passwordRecovery) {
              _passwordRecovery = true;
              _linkFailed = false;
              _linkExpired = false;
            }
            if (state.event == AuthChangeEvent.signedOut) {
              _passwordRecovery = false;
            }
            notifyListeners();
          },
          onError: (Object _) {
            if (!callback.isCallback && !_passwordRecovery) return;
            _passwordRecovery = false;
            _linkFailed = true;
            notifyListeners();
          },
        );
  }

  late final StreamSubscription<AuthState> _sub;
  final bool Function() _sessionExists;
  bool _passwordRecovery = false;
  bool _linkFailed = false;
  bool _linkExpired = false;
  bool get authLinkFailed => _linkFailed;
  bool get authLinkExpired => _linkExpired;
  void dismissAuthLinkError() {
    AuthLinkStartup.callback = const AuthLinkCallback();
    _linkFailed = false;
    _linkExpired = false;
    notifyListeners();
  }

  bool get isLoggedIn => _sessionExists();
  bool get isPasswordRecovery => _passwordRecovery;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
