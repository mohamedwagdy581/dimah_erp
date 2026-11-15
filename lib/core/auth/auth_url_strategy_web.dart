import 'package:flutter_web_plugins/url_strategy.dart';
import 'auth_link_callback.dart';

class AuthHashUrlStrategy extends HashUrlStrategy {
  AuthHashUrlStrategy([super.platformLocation]);
  @override
  String getPath() => authSafeHashPath(super.getPath());
}

void configureAuthUrlStrategy() => setUrlStrategy(AuthHashUrlStrategy());
