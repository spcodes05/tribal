/// Centralized asset path constants for the TRIBAL app.
///
/// PLACEMENT GUIDE:
/// ─────────────────────────────────────────────────────────────────
/// assets/images/
///   logo.png            → TRIBAL logo (white, used on dark bg)
///   onboarding_1.jpg    → Group of friends on a trek / outdoor activity
///   onboarding_2.jpg    → People collaborating around a laptop (roommate vibe)
///   onboarding_3.jpg    → Person in a safe, bright indoor setting
///
/// assets/icons/
///   ic_location_pin.svg → Location/pin icon (Onboarding 1)
///   ic_people.svg       → People/group icon (Onboarding 2)
///   ic_shield.svg       → Shield/safety icon (Onboarding 3)
///   ic_google.svg       → Google "G" logo
///   ic_apple.svg        → Apple  logo
/// ─────────────────────────────────────────────────────────────────
class AppAssets {
  AppAssets._();

  // Images
  static const String logo = 'assets/images/logo.png';
  static const String onboarding1 = 'assets/images/onboarding_1.jpg';
  static const String onboarding2 = 'assets/images/onboarding_2.jpg';
  static const String onboarding3 = 'assets/images/onboarding_3.jpg';

  // Icons
  static const String icLocationPin = 'assets/icons/ic_location_pin.svg';
  static const String icPeople = 'assets/icons/ic_people.svg';
  static const String icShield = 'assets/icons/ic_shield.svg';
  static const String icGoogle = 'assets/icons/ic_google.svg';
  static const String icApple = 'assets/icons/ic_apple.svg';
}
