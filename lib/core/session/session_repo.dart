import 'app_user.dart';

abstract class SessionRepo {
  Future<AppUser?> getCurrentAppUser();
}
