part of 'app_router.dart';

String? _redirect(BuildContext context, GoRouterState state) {
  final loggedIn = AppRouter.auth.isLoggedIn;
  final loc = state.matchedLocation;

  if (loc == AppRoutes.splash) {
    return null;
  }
  if (!loggedIn && loc != AppRoutes.login) {
    return AppRoutes.login;
  }
  if (loggedIn && loc == AppRoutes.login) {
    return AppRoutes.dashboard;
  }
  return null;
}
