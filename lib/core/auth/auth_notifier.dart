import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _sub;

  bool get isLoggedIn => Supabase.instance.client.auth.currentSession != null;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
