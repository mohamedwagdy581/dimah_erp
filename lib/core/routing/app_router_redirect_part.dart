part of 'app_router.dart';

String? _redirect(BuildContext context, GoRouterState state) {
  final loggedIn = AppRouter.auth.isLoggedIn;
  final loc = state.matchedLocation;
  if (AppRouter.auth.authLinkFailed) {
    return loc == AppRoutes.authLinkError ? null : AppRoutes.authLinkError;
  }

  if (loggedIn &&
      AppRouter.auth.isPasswordRecovery &&
      loc != AppRoutes.resetPassword) {
    return AppRoutes.resetPassword;
  }
  if (loc == AppRoutes.splash) {
    return null;
  }
  if (!loggedIn && loc != AppRoutes.login && loc != AppRoutes.recoverPassword) {
    return AppRoutes.login;
  }
  if (loggedIn && loc == AppRoutes.login) {
    return AppRoutes.dashboard;
  }
  return null;
}
