import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/profile_setup_controller.dart';
import '../../controllers/explore_controller.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../controllers/onboarding_controller.dart';
import '../../services/auth_service.dart';
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
import '../../views/explore/explore_screen.dart';
import '../../views/events/activity_detail_screen.dart';
import '../../views/events/create_activity_screen.dart';
import '../../views/events/location_picker_screen.dart';
import '../../views/events/notifications_screen.dart';
import '../../views/events/search_screen.dart';
import '../../views/events/see_all_screen.dart';
import '../../views/chat/chat_list_screen.dart';
import '../../views/chat/chat_screen.dart';
import '../../models/chat_model.dart';
import '../../views/safety/safety_screen.dart';
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
import '../../views/safety/trusted_contacts_screen.dart';
import '../../views/profile/tribe_status_screen.dart';
import '../../views/profile/other_user_profile_screen.dart';
import '../../views/profile/profile_settings_screen.dart';
import '../../views/profile/mutual_activities_screen.dart';
import '../../models/profile_model.dart';


class AppRoutes {
  AppRoutes._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String onboarding           = '/onboarding';
  static const String login                = '/login';
  static const String signup               = '/signup';
  static const String verifyEmail          = '/verify-email';

  // ── Profile completion ────────────────────────────────────────────────────
  static const String phoneVerification    = '/phone-verification';
  static const String genderSelection      = '/gender-selection';
  static const String socialVerification   = '/social-verification';
  static const String profileSetup         = '/profile-setup';
  static const String findingTribe         = '/finding-tribe';

  // ── Main app ──────────────────────────────────────────────────────────────
  static const String home                 = '/home';
  static const String explore              = '/explore';
  static const String activityDetail       = '/activity';
  static const String createActivity       = '/activity/create';
  static const String locationPicker       = '/activity/location-picker';
  static const String notifications        = '/notifications';
  static const String search               = '/search';
  static const String seeAllActivities     = '/see-all/activities';
  static const String seeAllPeople         = '/see-all/people';

  // ── Chat ──────────────────────────────────────────────────────────────────
  static const String chatList             = '/chat';
  static const String chatConversation     = '/chat/:id';

  // ── Roommate ──────────────────────────────────────────────────────────────
  static const String roommateHome             = '/roommate';
  static const String roommateIntro            = '/roommate/intro';
  static const String roommateBudget           = '/roommate/budget';
  static const String roommateSleepSchedule    = '/roommate/sleep-schedule';
  static const String roommateSmoking          = '/roommate/smoking';
  static const String roommateDrinking         = '/roommate/drinking';
  static const String roommateCleanliness      = '/roommate/cleanliness';
  static const String roommateNoiseLevel       = '/roommate/noise-level';
  static const String roommateGuests           = '/roommate/guests';
  static const String roommateFood             = '/roommate/food';
  static const String roommatePets             = '/roommate/pets';
  static const String roommateStudyHabit       = '/roommate/study-habit';
  static const String roommateInterests        = '/roommate/interests';
  static const String roommateGenderPreference = '/roommate/gender-preference';
  static const String roommateRoomType = '/roommate/room-type';
  static const String roommateReview = '/roommate/review';
  static const String roommateFinding = '/roommate/finding';

  static const String tribeStatus = '/tribe-status';
  static const String profileSettings = '/tribe-status/settings';
  static const String otherUserProfile = '/profile/:id';
  static const String mutualActivities = '/profile/:id/mutual-activities';

  static String otherUserProfilePath(int userId) =>
      otherUserProfile.replaceFirst(':id', userId.toString());

  /// Builds the concrete path for [mutualActivities], e.g.
  /// mutualActivitiesPath(42) -> '/profile/42/mutual-activities'.
  static String mutualActivitiesPath(int userId) =>
      mutualActivities.replaceFirst(':id', userId.toString());

  /// The root GoRouter instance.
  static final GoRouter router = GoRouter(
    initialLocation: onboarding,
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      final isEntryRoute = loc == '/' || loc == onboarding || loc == login || loc == signup;
      if (!isEntryRoute) return null;

      final seenOnboarding = await OnboardingController.hasSeenOnboarding();
      if (!seenOnboarding) {
        return loc == onboarding ? null : onboarding;
      }

      final loggedIn = await AuthService.instance.hasActiveSession();
      if (loggedIn) return home;
      return (loc == onboarding || loc == '/') ? login : null;
    },
    routes: [

      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(path: onboarding, name: 'onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: login,      name: 'login',      builder: (_, __) => const LoginScreen()),
      GoRoute(path: signup,     name: 'signup',     builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: verifyEmail,
        name: 'verifyEmail',
        builder: (_, state) => VerifyEmailScreen(
            initialEmail: state.uri.queryParameters['email']),
      ),

      // ── Main app ──────────────────────────────────────────────────────────
      GoRoute(path: home, name: 'home', builder: (_, __) => const HomeScreen()),

      GoRoute(
        path: explore,
        name: 'explore',
        builder: (_, __) => ChangeNotifierProvider(
          create: (_) => ExploreController(),
          child: const ExploreScreen(),
        ),
      ),

      GoRoute(
        path: activityDetail,
        name: 'activityDetail',
        builder: (_, state) =>
            ActivityDetailScreen(activityId: state.extra as int),
      ),
      GoRoute(
        path: createActivity,
        name: 'createActivity',
        builder: (_, __) => const CreateActivityScreen(),
      ),
      GoRoute(
        path: locationPicker,
        name: 'locationPicker',
        builder: (_, state) => LocationPickerScreen(
          initial: state.extra as dynamic,
        ),
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

      // ── Safety ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/safety',
        name: 'safety',
        builder: (_, __) => const SafetyScreen(),
      ),

      // ── Chat ──────────────────────────────────────────────────────────────
      GoRoute(
        path: chatList,
        name: 'chatList',
        builder: (_, __) => const ChatListScreen(),
      ),
      GoRoute(
        path: chatConversation,
        name: 'chatConversation',
        builder: (_, state) {
          final args = state.extra as ChatConversationArgs?;
          final idFromPath = int.tryParse(state.pathParameters['id'] ?? '');
          return ChatScreen(
            args: args ??
                ChatConversationArgs(
                  chatId: idFromPath ?? 0,
                  otherUserFullName: 'Conversation',
                ),
          );
        },
      ),


      // -- Your Tribe Status / Other User Profile ------------------------
      GoRoute(
        path: tribeStatus,
        name: 'tribeStatus',
        builder: (_, __) => const TribeStatusScreen(),
      ),
      GoRoute(
        path: profileSettings,
        name: 'profileSettings',
        builder: (_, __) => const ProfileSettingsScreen(),
      ),
      GoRoute(
        path: otherUserProfile,
        name: 'otherUserProfile',
        builder: (_, state) {
          final userId = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final args = state.extra as OtherProfileNavArgs?;
          return OtherUserProfileScreen(userId: userId, navArgs: args);
        },
      ),

      GoRoute(
        path: mutualActivities,
        name: 'mutualActivities',
        builder: (_, state) {
          final userId = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return MutualActivitiesScreen(userId: userId);
        },
      ),



      // -- Profile Completion Flow --------------------------------------
      // Wrapped in a single ChangeNotifierProvider so ProfileSetupController
      // state (phone, gender, socials, profile) persists across all 5 routes
      // below, then is cleanly disposed when the user exits the flow.

      // ── Profile completion ─────────────────────────────────────────────────

      ShellRoute(
        builder: (context, state, child) =>
            ChangeNotifierProvider<ProfileSetupController>(
              create: (_) => ProfileSetupController(),
              child: child,
            ),
        routes: [
          GoRoute(path: phoneVerification,  name: 'phoneVerification',  builder: (_, __) => const PhoneVerificationScreen()),
          GoRoute(path: genderSelection,    name: 'genderSelection',    builder: (_, __) => const GenderSelectionScreen()),
          GoRoute(path: socialVerification, name: 'socialVerification', builder: (_, __) => const SocialVerificationScreen()),
          GoRoute(path: profileSetup,       name: 'profileSetup',       builder: (_, __) => const ProfileSetupScreen()),
          GoRoute(path: findingTribe,       name: 'findingTribe',       builder: (_, __) => const FindingTribeLoadingScreen()),
        ],
      ),

      // ── Roommate ───────────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            ChangeNotifierProvider<RoommateQuizController>(
              create: (_) => RoommateQuizController(),
              child: child,
            ),
        routes: [
          GoRoute(path: roommateHome,             name: 'roommateHome',             builder: (_, __) => const RoommateHomeScreen()),
          GoRoute(path: roommateIntro,            name: 'roommateIntro',            builder: (_, __) => const RoommateIntroScreen()),
          GoRoute(path: roommateBudget,           name: 'roommateBudget',           builder: (_, __) => const BudgetScreen()),
          GoRoute(path: roommateSleepSchedule,    name: 'roommateSleepSchedule',    builder: (_, __) => const SleepScheduleScreen()),
          GoRoute(path: roommateSmoking,          name: 'roommateSmoking',          builder: (_, __) => const SmokingScreen()),
          GoRoute(path: roommateDrinking,         name: 'roommateDrinking',         builder: (_, __) => const DrinkingScreen()),
          GoRoute(path: roommateCleanliness,      name: 'roommateCleanliness',      builder: (_, __) => const CleanlinessScreen()),
          GoRoute(path: roommateNoiseLevel,       name: 'roommateNoiseLevel',       builder: (_, __) => const NoiseLevelScreen()),
          GoRoute(path: roommateGuests,           name: 'roommateGuests',           builder: (_, __) => const GuestsPreferenceScreen()),
          GoRoute(path: roommateFood,             name: 'roommateFood',             builder: (_, __) => const FoodPreferenceScreen()),
          GoRoute(path: roommatePets,             name: 'roommatePets',             builder: (_, __) => const PetsScreen()),
          GoRoute(path: roommateStudyHabit,       name: 'roommateStudyHabit',       builder: (_, __) => const StudyHabitScreen()),
          GoRoute(path: roommateInterests,        name: 'roommateInterests',        builder: (_, __) => const InterestsScreen()),
          GoRoute(path: roommateGenderPreference, name: 'roommateGenderPreference', builder: (_, __) => const GenderPreferenceScreen()),
          GoRoute(path: roommateRoomType,         name: 'roommateRoomType',         builder: (_, __) => const RoomTypePreferenceScreen()),
          GoRoute(path: roommateReview,           name: 'roommateReview',           builder: (_, __) => const ReviewScreen()),
          GoRoute(path: roommateFinding,          name: 'roommateFinding',          builder: (_, __) => const FindingRoommateScreen()),
          GoRoute(
            path: '/safety/trusted-contacts',
            name: 'trustedContacts',
            builder: (_, __) => const TrustedContactsScreen(),
          ),
        ],
      ),
    ],
  );
}