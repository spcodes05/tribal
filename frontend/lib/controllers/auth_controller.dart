import 'package:flutter/material.dart';
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

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

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

    _setStatus(AuthStatus.loading);
    try {
      _currentUser = await AuthService.instance.loginWithEmail(
        email: loginEmailController.text.trim(),
        password: loginPasswordController.text,
      );
      _setStatus(AuthStatus.success);
      return true;
    } on AuthException catch (e) {
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
      _setStatus(AuthStatus.success);
      return true;
    } on AuthException catch (e) {
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
