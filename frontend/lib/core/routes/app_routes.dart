import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../views/onboarding/onboarding_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/auth/signup_screen.dart';

/// Named route constants and GoRouter configuration for TRIBAL.
///
/// Navigation flow:
///   /onboarding → /login ↔ /signup
class AppRoutes {
  AppRoutes._();

  // Route name constants
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';

  /// The root GoRouter instance.
  /// Initial location defaults to onboarding; call [goToLogin] to skip.
  static final GoRouter router = GoRouter(
    initialLocation: onboarding,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (BuildContext context, GoRouterState state) =>
        const OnboardingScreen(),
      ),
      GoRoute(
        path: login,
        name: 'login',
        builder: (BuildContext context, GoRouterState state) =>
        const LoginScreen(),
      ),
      GoRoute(
        path: signup,
        name: 'signup',
        builder: (BuildContext context, GoRouterState state) =>
        const SignupScreen(),
      ),
    ],
  );
}
