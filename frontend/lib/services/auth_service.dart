import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../core/network/token_storage.dart';
import '../models/user_model.dart';

/// Authentication service layer for TRIBAL.
///
/// Talks to the Django backend's `apps.users` endpoints. Every method
/// throws an [ApiException] on failure (network error, validation error,
/// or auth error) — callers (controllers) catch this single type.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Dio get _dio => ApiClient.instance.dio;

  // ── Registration ────────────────────────────────────────────────────────────

  /// POST /api/users/register/
  ///
  /// Creates the account and stores the returned JWT tokens. Note the
  /// backend sends a verification email (printed to the Django console in
  /// dev) and the account is NOT fully usable — [LoginView] blocks login
  /// for unverified emails — until that link is opened.
  Future<UserModel> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: {
          'full_name': fullName,
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>;
      await TokenStorage.instance.saveTokens(
        access: tokens['access'] as String,
        refresh: tokens['refresh'] as String,
      );

      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ── Login ───────────────────────────────────────────────────────────────────

  /// POST /api/users/login/
  ///
  /// Throws [ApiException] with `code == 'email_not_verified'` if the
  /// backend rejects the login because the email link hasn't been clicked.
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>;
      await TokenStorage.instance.saveTokens(
        access: tokens['access'] as String,
        refresh: tokens['refresh'] as String,
      );

      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ── Email Verification ──────────────────────────────────────────────────────

  /// POST /api/users/verify-email/
  /// Call this with the token extracted from the verification link/email.
  Future<void> verifyEmail(String token) async {
    try {
      await _dio.post(ApiConfig.verifyEmail, data: {'token': token});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ── Current user ─────────────────────────────────────────────────────────────

  /// GET /api/users/me/
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConfig.me);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ── Google / Apple Sign-In ───────────────────────────────────────────────────
  // Not implemented on the backend yet — kept as explicit stubs so the UI
  // can show a clear "not available yet" message instead of pretending
  // to succeed.

  Future<UserModel> signInWithGoogle() async {
    throw const ApiException('Google Sign-In is not available yet.');
  }

  Future<UserModel> signInWithApple() async {
    throw const ApiException('Apple Sign-In is not available yet.');
  }

  // ── Logout ───────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await TokenStorage.instance.clear();
  }

  // ── Session check ────────────────────────────────────────────────────────────

  Future<bool> hasActiveSession() => TokenStorage.instance.hasTokens();
}
