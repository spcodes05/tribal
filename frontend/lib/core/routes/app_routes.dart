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
import '../../controllers/roommate_quiz_controller.dart';
import '../../views/roommate/roommate_home_screen.dart';
import '../../views/roommate/roommate_intro_screen.dart';
import '../../views/roommate/budget_screen.dart';
import '../../views/roommate/sleep_schedule_screen.dart';
import '../../views/roommate/smoking_screen.dart';
import '../../views/roommate/drinking_screen.dart';
import '../../views/roommate/cleanliness_screen.dart';
import '../../views/roommate/noise_level_screen.dart';
import '../../views/roommate/guests_preference_screen.dart';
import '../../views/roommate/food_preference_screen.dart';
import '../../views/roommate/pets_screen.dart';
import '../../views/roommate/study_habit_screen.dart';
import '../../views/roommate/interests_screen.dart';
import '../../views/roommate/gender_preference_screen.dart';
import '../../views/roommate/room_type_preference_screen.dart';
import '../../views/roommate/review_screen.dart';
import '../../views/roommate/finding_roommate_screen.dart';
import '../../views/events/activity_detail_screen.dart';
import '../../views/events/create_activity_screen.dart';
import '../../views/events/notifications_screen.dart';
import '../../views/events/search_screen.dart';
import '../../views/events/see_all_screen.dart';

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
  static const String verifyEmail = '/verify-email';


  // Profile completion flow
  static const String phoneVerification = '/phone-verification';
  static const String genderSelection = '/gender-selection';
  static const String socialVerification = '/social-verification';
  static const String profileSetup = '/profile-setup';
  static const String findingTribe = '/finding-tribe';
  static const String home = '/home';
  static const String roommateHome = '/roommate';
  static const String roommateIntro = '/roommate/intro';
  static const String roommateBudget = '/roommate/budget';
  static const String roommateSleepSchedule = '/roommate/sleep-schedule';
  static const String roommateSmoking = '/roommate/smoking';
  static const String roommateDrinking = '/roommate/drinking';
  static const String roommateCleanliness = '/roommate/cleanliness';
  static const String roommateNoiseLevel = '/roommate/noise-level';
  static const String roommateGuests = '/roommate/guests';
  static const String roommateFood = '/roommate/food';
  static const String roommatePets = '/roommate/pets';
  static const String roommateStudyHabit = '/roommate/study-habit';
  static const String roommateInterests = '/roommate/interests';
  static const String roommateGenderPreference = '/roommate/gender-preference';
  static const String roommateRoomType = '/roommate/room-type';
  static const String roommateReview = '/roommate/review';
  static const String roommateFinding = '/roommate/finding';
  static const String activityDetail = '/activity';
  static const String createActivity = '/activity/create';
  static const String notifications = '/notifications';
  static const String search = '/search';
  static const String seeAllActivities = '/see-all/activities';
  static const String seeAllPeople = '/see-all/people';

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
      GoRoute(
        path: verifyEmail,
        name: 'verifyEmail',
        builder: (BuildContext context, GoRouterState state) =>
            VerifyEmailScreen(
                initialEmail: state.uri.queryParameters['email']
            ),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
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

      ShellRoute(
        builder: (context, state, child) {
          return ChangeNotifierProvider<RoommateQuizController>(
            create: (_) => RoommateQuizController(),
            child: child,
          );
        },
        routes: [
          GoRoute(path: roommateHome, name: 'roommateHome', builder: (c, s) => const RoommateHomeScreen()),
          GoRoute(path: roommateIntro, name: 'roommateIntro', builder: (c, s) => const RoommateIntroScreen()),
          GoRoute(path: roommateBudget, name: 'roommateBudget', builder: (c, s) => const BudgetScreen()),
          GoRoute(path: roommateSleepSchedule, name: 'roommateSleepSchedule', builder: (c, s) => const SleepScheduleScreen()),
          GoRoute(path: roommateSmoking, name: 'roommateSmoking', builder: (c, s) => const SmokingScreen()),
          GoRoute(path: roommateDrinking, name: 'roommateDrinking', builder: (c, s) => const DrinkingScreen()),
          GoRoute(path: roommateCleanliness, name: 'roommateCleanliness', builder: (c, s) => const CleanlinessScreen()),
          GoRoute(path: roommateNoiseLevel, name: 'roommateNoiseLevel', builder: (c, s) => const NoiseLevelScreen()),
          GoRoute(path: roommateGuests, name: 'roommateGuests', builder: (c, s) => const GuestsPreferenceScreen()),
          GoRoute(path: roommateFood, name: 'roommateFood', builder: (c, s) => const FoodPreferenceScreen()),
          GoRoute(path: roommatePets, name: 'roommatePets', builder: (c, s) => const PetsScreen()),
          GoRoute(path: roommateStudyHabit, name: 'roommateStudyHabit', builder: (c, s) => const StudyHabitScreen()),
          GoRoute(path: roommateInterests, name: 'roommateInterests', builder: (c, s) => const InterestsScreen()),
          GoRoute(path: roommateGenderPreference, name: 'roommateGenderPreference', builder: (c, s) => const GenderPreferenceScreen()),
          GoRoute(path: roommateRoomType, name: 'roommateRoomType', builder: (c, s) => const RoomTypePreferenceScreen()),
          GoRoute(path: roommateReview, name: 'roommateReview', builder: (c, s) => const ReviewScreen()),
          GoRoute(path: roommateFinding, name: 'roommateFinding', builder: (c, s) => const FindingRoommateScreen()),
        ],
      ),
    ],
  );
}
