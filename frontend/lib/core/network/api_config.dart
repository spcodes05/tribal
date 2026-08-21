/// Backend API configuration.
///
/// IMPORTANT — pick the right base URL for where you're running Django:
///   • iOS simulator / Flutter web / macOS / Windows / Linux desktop → 127.0.0.1
///   • Android emulator (AVD)                                       → 10.0.2.2
///   • Physical device on the same WiFi as your dev machine         → your PC's LAN IP (e.g. 192.168.1.50)
///
/// Currently set for iOS simulator / web / desktop testing.
class ApiConfig {
  ApiConfig._();



  static const String baseUrl = 'http://10.0.2.2:8000/api';


  // ── Users endpoints (apps/users/urls.py) ──────────────────────────────────
  static const String register = '/users/register/';
  static const String verifyEmail = '/users/verify-email/';
  static const String resendVerification = '/users/resend-verification/';
  static const String login = '/users/login/';
  static const String gender = '/users/gender/';
  static const String interests = '/users/interests/';
  static const String me = '/users/me/';

  static const String userLocation = '/safety/location/';
  static const String interestsList = '/users/interests/';

  static const String meTribeStatus = '/users/me/tribe-status/';
  static const String meUpdateProfile = '/users/me/update/';
  static const String meProfileImage = '/users/me/profile-image/';
  static String publicProfile(int userId) => '/users/$userId/profile/';
  static String blockUser(int userId) => '/users/$userId/block/';
  static String reportUser(int userId) => '/users/$userId/report/';
  static String mutualActivities(int userId) => '/users/$userId/mutual-activities/';

  // ── Events endpoints (apps/events/urls.py) ───────────────────────────────
  static const String homeFeed = '/events/home/';
  static const String activities = '/events/activities/';
  static const String activitiesMap = '/events/activities/map/';
  static String activityDetail(int id) => '/events/activities/$id/';
  static String joinActivity(int id) => '/events/activities/$id/join/';
  static const String notifications = '/events/notifications/';
  static const String notificationsRead = '/events/notifications/read/';
  static const String search = '/events/search/';

  // ── Roommate endpoints ─────────────────────────────────────────────
  static const String roommateProfile = '/roommate/profile/';
  static const String roommateFind = '/roommate/find/';
  static const String roommateMatchesRefresh = '/roommate/matches/refresh/';



// ── Chat endpoints (apps/chat/urls.py) ─────────────────────────────────
  static const String chatList = '/chat/';
  static const String chatStart = '/chat/start/';
  static String chatMessages(int chatId) => '/chat/$chatId/';
  static String chatSend(int chatId) => '/chat/$chatId/send/';
  static String messageRead(int messageId) => '/chat/message/$messageId/read/';
  static String messageDelete(int messageId) => '/chat/message/$messageId/';

  // ── Safety endpoints (apps/safety/urls.py) ─────────────────────────────
  static const String safetySettings = '/safety/settings/';
  static const String trustedContacts = '/safety/trusted-contacts/';
  static String trustedContactDelete(int pk) => '/safety/trusted-contacts/$pk/';
  static const String safetyLocationUpdate = '/safety/location/';
  static String trustedUserLocation(int userId) => '/safety/location/$userId/';
  static const String sosActivate = '/safety/sos/activate/';
  static const String sosEnd = '/safety/sos/end/';
  // ── User search endpoint (apps/users/urls.py) ───────────────────────────
  static const String userSearch = '/users/search/';

  // ── Token endpoints (config/urls.py — simplejwt) ──────────────────────────
  static const String tokenRefresh = '/token/refresh/';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}