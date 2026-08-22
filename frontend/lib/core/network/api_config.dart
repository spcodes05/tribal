/// Backend API configuration.
///
/// IMPORTANT — pick the right base URL for where you're running Django:
///   • iOS simulator / Flutter web / macOS / Windows / Linux desktop → 127.0.0.1
///   • Android emulator (AVD)                                       → 10.0.2.2
///   • Physical device on the same WiFi as your dev machine         → your PC's LAN IP 192.168.1.75
///
/// Currently set for iOS simulator / web / desktop testing.
class ApiConfig {
  ApiConfig._();


  static const String baseUrl = 'https://tribal-h9ui.onrender.com';

  static const String register = '/api/users/register/';
  static const String verifyEmail = '/api/users/verify-email/';
  static const String resendVerification = '/api/users/resend-verification/';
  static const String login = '/api/users/login/';
  static const String gender = '/api/users/gender/';
  static const String interests = '/api/users/interests/';
  static const String me = '/api/users/me/';

  static const String userLocation = '/api/safety/location/';
  static const String interestsList = '/api/users/interests/';

  static const String meTribeStatus = '/api/users/me/tribe-status/';
  static const String meUpdateProfile = '/api/users/me/update/';
  static const String meProfileImage = '/api/users/me/profile-image/';
  static String publicProfile(int userId) => '/api/users/$userId/profile/';
  static String blockUser(int userId) => '/api/users/$userId/block/';
  static String reportUser(int userId) => '/api/users/$userId/report/';
  static String mutualActivities(int userId) =>
      '/api/users/$userId/mutual-activities/';

  static const String homeFeed = '/api/events/home/';
  static const String activities = '/api/events/activities/';
  static const String activitiesMap = '/api/events/activities/map/';
  static String activityDetail(int id) => '/api/events/activities/$id/';
  static String joinActivity(int id) => '/api/events/activities/$id/join/';
  static const String notifications = '/api/events/notifications/';
  static const String notificationsRead = '/api/events/notifications/read/';
  static const String search = '/api/events/search/';

  static const String roommateProfile = '/api/roommate/profile/';
  static const String roommateFind = '/api/roommate/find/';
  static const String roommateMatchesRefresh =
      '/api/roommate/matches/refresh/';

  static const String chatList = '/api/chat/';
  static const String chatStart = '/api/chat/start/';
  static String chatMessages(int chatId) => '/api/chat/$chatId/';
  static String chatSend(int chatId) => '/api/chat/$chatId/send/';
  static String messageRead(int messageId) =>
      '/api/chat/message/$messageId/read/';
  static String messageDelete(int messageId) =>
      '/api/chat/message/$messageId/';

  static const String safetySettings = '/api/safety/settings/';
  static const String trustedContacts = '/api/safety/trusted-contacts/';
  static String trustedContactDelete(int pk) =>
      '/api/safety/trusted-contacts/$pk/';
  static const String safetyLocationUpdate = '/api/safety/location/';
  static String trustedUserLocation(int userId) =>
      '/api/safety/location/$userId/';
  static const String sosActivate = '/api/safety/sos/activate/';
  static const String sosEnd = '/api/safety/sos/end/';

  static const String userSearch = '/api/users/search/';

  static const String tokenRefresh = '/api/token/refresh/';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}