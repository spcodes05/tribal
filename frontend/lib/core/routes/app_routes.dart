import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/profile_setup_controller.dart';
import '../../views/onboarding/onboarding_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/auth/signup_screen.dart';
import '../../views/profile_completion/phone_verification_screen.dart';
import '../../views/profile_completion/gender_selection_screen.dart';
import '../../views/profile_completion/social_verification_screen.dart';
import '../../views/profile_completion/profile_setup_screen.dart';
import '../../views/profile_completion/finding_tribe_loading_screen.dart';

/// Named route constants and GoRouter configuration for TRIBAL.
///
/// Navigation flow:
///   /onboarding -> /login <-> /signup
///                              | (after account creation)
///                         /phone-verification
///                              |
///                         /gender-selection
///                              |
///                         /social-verification
///                              |
///                         /profile-setup
///                              |
///                         /finding-tribe
///
/// The four profile-completion screens (phone verification through profile
/// setup) plus the final loading screen share a single
/// [ProfileSetupController] instance so data persists across steps. It's
/// provided once via a [ShellRoute] wrapper around the whole sub-flow and
/// disposed automatically when the user leaves it.
class AppRoutes {
  AppRoutes._();

  // Route name constants
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';

  // Profile completion flow
  static const String phoneVerification = '/phone-verification';
  static const String genderSelection = '/gender-selection';
  static const String socialVerification = '/social-verification';
  static const String profileSetup = '/profile-setup';
  static const String findingTribe = '/finding-tribe';

  /// The root GoRouter instance.
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

      // -- Profile Completion Flow --------------------------------------
      // Wrapped in a single ChangeNotifierProvider so ProfileSetupController
      // state (phone, gender, socials, profile) persists across all 5 routes
      // below, then is cleanly disposed when the user exits the flow.
      ShellRoute(
        builder: (context, state, child) {
          return ChangeNotifierProvider<ProfileSetupController>(
            create: (_) => ProfileSetupController(),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: phoneVerification,
            name: 'phoneVerification',
            builder: (context, state) => const PhoneVerificationScreen(),
          ),
          GoRoute(
            path: genderSelection,
            name: 'genderSelection',
            builder: (context, state) => const GenderSelectionScreen(),
          ),
          GoRoute(
            path: socialVerification,
            name: 'socialVerification',
            builder: (context, state) => const SocialVerificationScreen(),
          ),
          GoRoute(
            path: profileSetup,
            name: 'profileSetup',
            builder: (context, state) => const ProfileSetupScreen(),
          ),
          GoRoute(
            path: findingTribe,
            name: 'findingTribe',
            builder: (context, state) => const FindingTribeLoadingScreen(),
          ),
        ],
      ),
    ],
  );
}
