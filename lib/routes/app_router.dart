import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/main_shell.dart';

/// Centralized named-route definitions with authentication guards.
///
/// Protected routes redirect to [login] when no token is found.
/// Authenticated users visiting [login] or [register] are redirected to [mainShell].
class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String mainShell = '/main';

  static final router = GoRouter(
    initialLocation: splash,
    redirect: _guard,
    routes: [
      GoRoute(
        path: splash,
        pageBuilder: (context, state) => _fadePage(const SplashScreen(), state),
      ),
      GoRoute(
        path: login,
        pageBuilder: (context, state) => _slidePage(const LoginScreen(), state),
      ),
      GoRoute(
        path: register,
        pageBuilder: (context, state) => _slidePage(const RegisterScreen(), state),
      ),
      GoRoute(
        path: mainShell,
        pageBuilder: (context, state) => _fadePage(const MainShell(), state),
      ),
    ],
  );

  static Future<String?> _guard(BuildContext context, GoRouterState state) async {
    final loggedIn = await AuthService.isLoggedIn();
    final onPublicRoute = state.matchedLocation == login ||
        state.matchedLocation == register ||
        state.matchedLocation == splash;

    if (!loggedIn && !onPublicRoute) return login;
    if (loggedIn && (state.matchedLocation == login || state.matchedLocation == register)) {
      return mainShell;
    }
    return null;
  }

  static CustomTransitionPage<void> _fadePage(Widget page, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: page,
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  static CustomTransitionPage<void> _slidePage(Widget page, GoRouterState state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: page,
      transitionsBuilder: (context, animation, secondary, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
