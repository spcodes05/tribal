import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Represents the current async state of an auth operation.
enum AuthStatus { idle, loading, success, error }

/// Controller for the Authentication module.
///
/// Manages form field controllers, validation, loading state, and
/// delegates actual API calls to [AuthService].
class AuthController extends ChangeNotifier {
  // ── Shared State ────────────────────────────────────────────────────────────
  AuthStatus _status = AuthStatus.idle;
  AuthStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// True when the last login attempt failed specifically because the
  /// backend's email-verification gate rejected it (LoginView returns
  /// code: "email_not_verified"). The UI can use this to show a
  /// "check your inbox" message instead of a generic error.
  bool _isEmailNotVerified = false;
  bool get isEmailNotVerified => _isEmailNotVerified;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  /// The email a verification link/token was most recently sent to.
  /// Set after registration or a resend, so the verify-email screen
  /// always knows which address it's dealing with.
  String? _pendingVerificationEmail;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  // ── Login Form ──────────────────────────────────────────────────────────────
  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  // ── Signup Form ─────────────────────────────────────────────────────────────
  final TextEditingController signupNameController = TextEditingController();
  final TextEditingController signupEmailController = TextEditingController();
  final TextEditingController signupPasswordController = TextEditingController();
  final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  // ── UI Helpers ──────────────────────────────────────────────────────────────

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void _setStatus(AuthStatus s, {String? error}) {
    _status = s;
    _errorMessage = error;
    notifyListeners();
  }

  // ── Login ───────────────────────────────────────────────────────────────────

  Future<bool> login() async {
    if (!loginFormKey.currentState!.validate()) return false;

    _isEmailNotVerified = false;
    _setStatus(AuthStatus.loading);
    try {
      _currentUser = await AuthService.instance.loginWithEmail(
        email: loginEmailController.text.trim(),
        password: loginPasswordController.text,
      );
      _setStatus(AuthStatus.success);
      return true;
    } on ApiException catch (e) {
      _isEmailNotVerified = e.code == 'email_not_verified';
      _setStatus(AuthStatus.error, error: e.message);
      return false;
    } catch (_) {
      _setStatus(AuthStatus.error, error: 'Something went wrong. Please try again.');
      return false;
    }
  }

  // ── Sign Up ─────────────────────────────────────────────────────────────────

  Future<bool> register() async {
    if (!signupFormKey.currentState!.validate()) return false;

    _setStatus(AuthStatus.loading);
    try {
      _currentUser = await AuthService.instance.registerWithEmail(
        fullName: signupNameController.text.trim(),
        email: signupEmailController.text.trim(),
        password: signupPasswordController.text,
      );
      _pendingVerificationEmail = signupEmailController.text.trim();
      _setStatus(AuthStatus.success);
      return true;
    } on ApiException catch (e) {
      _setStatus(AuthStatus.error, error: e.message);
      return false;
    } catch (_) {
      _setStatus(AuthStatus.error, error: 'Something went wrong. Please try again.');
      return false;
    }
  }

  // ── Email Verification ─────────────────────────────────────────────────────

  /// Submits a verification token (pasted from the email link, or typed
  /// in manually during local dev when reading it off the Django console).
  Future<bool> verifyEmail(String token) async {
    _setStatus(AuthStatus.loading);
    try {
      await AuthService.instance.verifyEmail(token.trim());
      _setStatus(AuthStatus.success);
      return true;
    } on ApiException catch (e) {
      _setStatus(AuthStatus.error, error: e.message);
      return false;
    } catch (_) {
      _setStatus(AuthStatus.error, error: 'Something went wrong. Please try again.');
      return false;
    }
  }

  /// Asks the backend to generate a fresh token and re-send the email.
  Future<bool> resendVerification(String email) async {
    _setStatus(AuthStatus.loading);
    try {
      await AuthService.instance.resendVerification(email.trim());
      _pendingVerificationEmail = email.trim();
      _setStatus(AuthStatus.success);
      return true;
    } on ApiException catch (e) {
      _setStatus(AuthStatus.error, error: e.message);
      return false;
    } catch (_) {
      _setStatus(AuthStatus.error, error: 'Something went wrong. Please try again.');
      return false;
    }
  }

  // ── Social Sign-In ──────────────────────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    _setStatus(AuthStatus.loading);
    try {
      _currentUser = await AuthService.instance.signInWithGoogle();
      _setStatus(AuthStatus.success);
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: 'Google Sign-In not yet available.');
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    _setStatus(AuthStatus.loading);
    try {
      _currentUser = await AuthService.instance.signInWithApple();
      _setStatus(AuthStatus.success);
      return true;
    } catch (e) {
      _setStatus(AuthStatus.error, error: 'Apple Sign-In not yet available.');
      return false;
    }
  }

  // ── Reset ────────────────────────────────────────────────────────────────────

  void resetStatus() {
    _isEmailNotVerified = false;
    _setStatus(AuthStatus.idle, error: null);
  }

  @override
  void dispose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    signupNameController.dispose();
    signupEmailController.dispose();
    signupPasswordController.dispose();
    super.dispose();
  }
}
