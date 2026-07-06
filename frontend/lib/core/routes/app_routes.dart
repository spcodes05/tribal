import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/profile_setup_controller.dart';
import '../../views/onboarding/onboarding_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/auth/signup_screen.dart';
import '../../views/auth/verify_email_screen.dart';
import '../../views/profile_completion/phone_verification_screen.dart';
import '../../views/profile_completion/gender_selection_screen.dart';
import '../../views/profile_completion/social_verification_screen.dart';
import '../../views/profile_completion/profile_setup_screen.dart';
import '../../views/profile_completion/finding_tribe_loading_screen.dart';
import '../../views/home/home_screen.dart';
import '../../views/events/activity_detail_screen.dart';
import '../../views/events/create_activity_screen.dart';
import '../../views/events/notifications_screen.dart';
import '../../views/events/search_screen.dart';
import '../../views/events/see_all_screen.dart';

class AppRoutes {
  AppRoutes._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verifyEmail = '/verify-email';

  // ── Profile completion ────────────────────────────────────────────────────
  static const String phoneVerification = '/phone-verification';
  static const String genderSelection = '/gender-selection';
  static const String socialVerification = '/social-verification';
  static const String profileSetup = '/profile-setup';
  static const String findingTribe = '/finding-tribe';

  // ── Main app ──────────────────────────────────────────────────────────────
  static const String home = '/home';
  static const String activityDetail = '/activity';
  static const String createActivity = '/activity/create';
  static const String notifications = '/notifications';
  static const String search = '/search';
  static const String seeAllActivities = '/see-all/activities';
  static const String seeAllPeople = '/see-all/people';

  static final GoRouter router = GoRouter(
    initialLocation: onboarding,
    debugLogDiagnostics: false,
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: signup,
        name: 'signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: verifyEmail,
        name: 'verifyEmail',
        builder: (_, state) => VerifyEmailScreen(
            initialEmail: state.uri.queryParameters['email']),
      ),

      // ── Main app ──────────────────────────────────────────────────────────
      GoRoute(
        path: home,
        name: 'home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: activityDetail,
        name: 'activityDetail',
        builder: (_, state) => ActivityDetailScreen(
          activityId: state.extra as int,
        ),
      ),
      GoRoute(
        path: createActivity,
        name: 'createActivity',
        builder: (_, __) => const CreateActivityScreen(),
      ),
      GoRoute(
        path: notifications,
        name: 'notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: search,
        name: 'search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: seeAllActivities,
        name: 'seeAllActivities',
        builder: (_, __) => const SeeAllScreen(mode: SeeAllMode.activities),
      ),
      GoRoute(
        path: seeAllPeople,
        name: 'seeAllPeople',
        builder: (_, __) => const SeeAllScreen(mode: SeeAllMode.people),
      ),

      // ── Profile completion flow ────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ChangeNotifierProvider<ProfileSetupController>(
          create: (_) => ProfileSetupController(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: phoneVerification,
            name: 'phoneVerification',
            builder: (_, __) => const PhoneVerificationScreen(),
          ),
          GoRoute(
            path: genderSelection,
            name: 'genderSelection',
            builder: (_, __) => const GenderSelectionScreen(),
          ),
          GoRoute(
            path: socialVerification,
            name: 'socialVerification',
            builder: (_, __) => const SocialVerificationScreen(),
          ),
          GoRoute(
            path: profileSetup,
            name: 'profileSetup',
            builder: (_, __) => const ProfileSetupScreen(),
          ),
          GoRoute(
            path: findingTribe,
            name: 'findingTribe',
            builder: (_, __) => const FindingTribeLoadingScreen(),
          ),
        ],
      ),
    ],
  );
}
