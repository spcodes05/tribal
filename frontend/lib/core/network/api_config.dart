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

  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // ── Users endpoints (apps/users/urls.py) ──────────────────────────────────
  static const String register = '/users/register/';
  static const String verifyEmail = '/users/verify-email/';
  static const String login = '/users/login/';
  static const String gender = '/users/gender/';
  static const String interests = '/users/interests/';
  static const String me = '/users/me/';

  // ── Token endpoints (config/urls.py — simplejwt) ──────────────────────────
  static const String tokenRefresh = '/token/refresh/';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
