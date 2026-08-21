import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// The single source of truth for the LOGGED-IN user's own profile data
/// (currently just what the avatar needs: name + photo).
///
/// Provided once at the app root (see main.dart), exactly like
/// [HomeController] — it persists across navigation so every screen reads
/// from the same instance instead of fetching/caching its own copy.
///
/// Whenever the profile photo is uploaded or removed (Tribe Status), the UI
/// layer calls [updateProfile] on this controller, which calls
/// notifyListeners() — every widget watching it (via [UserAvatar.me],
/// see widgets/user_avatar.dart) rebuilds immediately. No screen refresh,
/// no restart, no per-screen wiring.
class CurrentUserController extends ChangeNotifier {
  String? _id;
  String? get id => _id;

  String? _fullName;
  String? get fullName => _fullName;

  String? _profileImage;
  String? get profileImage => _profileImage;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// Best-effort load from /users/me/. Called once at app start and again
  /// after login/onboarding completes. Fails silently if not authenticated
  /// yet — the avatar just shows a generic placeholder until it succeeds.
  Future<void> load() async {
    try {
      final user = await AuthService.instance.getCurrentUser();
      _id = user.id;
      _fullName = user.fullName;
      _profileImage = user.profileImage;
      _isLoaded = true;
      notifyListeners();
    } catch (_) {
      // Not authenticated yet, or a transient network error — harmless,
      // UserAvatar.me() just shows the generic fallback until the next
      // successful load() call (e.g. from HomeScreen.initState).
    }
  }

  /// Called directly after a successful profile-image upload/remove (Tribe
  /// Status) so every avatar in the app updates instantly, without an
  /// extra network round trip.
  void updateProfile({String? fullName, String? profileImage}) {
    if (fullName != null) _fullName = fullName;
    _profileImage = profileImage;
    _isLoaded = true;
    notifyListeners();
  }
}