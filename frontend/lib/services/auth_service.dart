import '../models/user_model.dart';

/// Authentication service layer for TRIBAL.
///
/// Currently contains stub implementations that simulate network behaviour.
/// Replace the method bodies with real Dio/Firebase calls when the backend
/// (NestJS + Firebase Auth) is available.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Login ───────────────────────────────────────────────────────────────────

  /// Authenticates a user with [email] and [password].
  ///
  /// Throws an [AuthException] on failure.
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    // TODO: Replace with real API call
    // final response = await dio.post('/auth/login', data: { email, password });
    await Future.delayed(const Duration(seconds: 1)); // simulate network
    return UserModel(
      id: 'stub-uid-001',
      fullName: 'Sampada Rai',
      email: email,
      trustScore: 72.0,
      isEmailVerified: true,
      createdAt: DateTime.now(),
    );
  }

  // ── Registration ────────────────────────────────────────────────────────────

  /// Registers a new user with the given credentials.
  ///
  /// Throws an [AuthException] on failure.
  Future<UserModel> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    // TODO: Replace with real API call
    // final response = await dio.post('/auth/register', data: { fullName, email, password });
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(
      id: 'stub-uid-002',
      fullName: fullName,
      email: email,
      trustScore: 10.0,
      isEmailVerified: false,
      createdAt: DateTime.now(),
    );
  }

  // ── Google Sign-In ───────────────────────────────────────────────────────────

  /// Initiates Google OAuth flow.
  ///
  /// TODO: Integrate google_sign_in package + Firebase Auth.
  Future<UserModel> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    throw UnimplementedError('Google Sign-In not yet integrated.');
  }

  // ── Apple Sign-In ────────────────────────────────────────────────────────────

  /// Initiates Apple Sign-In flow.
  ///
  /// TODO: Integrate sign_in_with_apple package + Firebase Auth.
  Future<UserModel> signInWithApple() async {
    await Future.delayed(const Duration(seconds: 1));
    throw UnimplementedError('Apple Sign-In not yet integrated.');
  }

  // ── Logout ───────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    // TODO: Clear tokens, call Firebase signOut
    await Future.delayed(const Duration(milliseconds: 300));
  }
}

/// Typed exception thrown by [AuthService] methods.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
