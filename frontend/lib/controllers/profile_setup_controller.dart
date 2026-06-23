import 'package:flutter/material.dart';
import '../models/onboarding_profile_model.dart';

/// Controller for the post-signup profile completion flow:
/// Phone Verification → Gender Selection → Social Verification → Profile Setup.
///
/// A single controller instance is provided at the top of the flow (see
/// [AppRoutes]) so data persists as the user moves between the four steps,
/// matching the pattern used by [AuthController] / [OnboardingController].
class ProfileSetupController extends ChangeNotifier {
  final OnboardingProfileModel profile = OnboardingProfileModel();

  // ── Phone Verification ──────────────────────────────────────────────────────

  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> phoneFormKey = GlobalKey<FormState>();

  bool _isVerifyingPhone = false;
  bool get isVerifyingPhone => _isVerifyingPhone;

  /// Nepal mobile numbers: 10 digits, starting with 9 (e.g. 98xxxxxxxx).
  bool get isPhoneValid {
    final digits = phoneController.text.trim();
    return RegExp(r'^9\d{9}$').hasMatch(digits);
  }

  void onPhoneChanged(String _) => notifyListeners();

  Future<void> submitPhone() async {
    if (!isPhoneValid) return;
    _isVerifyingPhone = true;
    notifyListeners();

    // TODO: Replace with real OTP-send API call
    await Future.delayed(const Duration(milliseconds: 800));

    profile.phoneNumber = phoneController.text.trim();
    profile.isPhoneVerified = true; // stubbed — OTP screen not in this scope
    _isVerifyingPhone = false;
    notifyListeners();
  }

  void skipPhone() {
    profile.phoneNumber = null;
    profile.isPhoneVerified = false;
    notifyListeners();
  }

  // ── Gender Selection ─────────────────────────────────────────────────────────

  void selectGender(Gender gender) {
    profile.gender = gender;
    notifyListeners();
  }

  bool get isGenderSelected => profile.gender != null;

  // ── Social Verification ──────────────────────────────────────────────────────

  /// Mock connect flow. Replace with real OAuth integration later.
  Future<void> toggleSocialConnection(SocialPlatform platform) async {
    final isCurrentlyConnected = profile.connectedSocials[platform] ?? false;

    if (!isCurrentlyConnected) {
      // Simulate a brief "connecting..." delay for realism.
      _connectingPlatform = platform;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 700));

      profile.connectedSocials[platform] = true;
      _connectingPlatform = null;
    } else {
      profile.connectedSocials[platform] = false;
    }
    notifyListeners();
  }

  SocialPlatform? _connectingPlatform;
  SocialPlatform? get connectingPlatform => _connectingPlatform;

  bool isConnected(SocialPlatform platform) =>
      profile.connectedSocials[platform] ?? false;

  // ── Profile Setup ────────────────────────────────────────────────────────────

  final TextEditingController aboutMeController = TextEditingController();
  static const int aboutMeMaxLength = 150;

  String? _profileImagePath;
  String? get profileImagePath => _profileImagePath;

  void setProfileImage(String path) {
    _profileImagePath = path;
    profile.profileImagePath = path;
    notifyListeners();
  }

  void onAboutMeChanged(String value) {
    profile.aboutMe = value;
    notifyListeners();
  }

  int get aboutMeRemainingChars =>
      aboutMeMaxLength - aboutMeController.text.length;

  void toggleInterest(String interest) {
    if (profile.interests.contains(interest)) {
      profile.interests.remove(interest);
    } else {
      profile.interests.add(interest);
    }
    notifyListeners();
  }

  bool isInterestSelected(String interest) =>
      profile.interests.contains(interest);

  bool get canFindTribe => profile.interests.isNotEmpty;

  // ── Final Submission ─────────────────────────────────────────────────────────

  bool _isSubmittingProfile = false;
  bool get isSubmittingProfile => _isSubmittingProfile;

  /// Simulates submitting the full profile to the backend.
  /// Replace with a real Dio POST to `/users/profile` once available.
  Future<void> submitProfile() async {
    _isSubmittingProfile = true;
    notifyListeners();

    // TODO: Replace with real API call using profile.toJson()
    await Future.delayed(const Duration(seconds: 2));

    _isSubmittingProfile = false;
    notifyListeners();
  }

  @override
  void dispose() {
    phoneController.dispose();
    aboutMeController.dispose();
    super.dispose();
  }
}
