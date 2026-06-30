/// Enum of supported genders for the gender selection step.
enum Gender { male, female, nonBinary, preferNotToSay }

/// Maps [Gender] to the exact string values Django's `GENDER_CHOICES`
/// expects (`backend/apps/users/models.py`). Do not use `.name` directly —
/// it produces `nonBinary`/`preferNotToSay`, which the backend rejects.
extension GenderApiValue on Gender {
  String get apiValue {
    switch (this) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      case Gender.nonBinary:
        return 'non_binary';
      case Gender.preferNotToSay:
        return 'prefer_not_to_say';
    }
  }

  static Gender? fromApiValue(String? value) {
    switch (value) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      case 'non_binary':
        return Gender.nonBinary;
      case 'prefer_not_to_say':
        return Gender.preferNotToSay;
      default:
        return null;
    }
  }
}

/// Enum of supported social platforms for the social verification step.
enum SocialPlatform { instagram, linkedin, facebook, github, spotify }

/// Aggregated data model collected across the post-signup profile
/// completion flow (Phone Verification → Gender → Social → Profile Setup).
///
/// This is intentionally a single flat model (rather than 4 separate ones)
/// since the whole flow is submitted together to the backend at the end.
/// Mirrors fields the NestJS "User & Trust Management" module expects.
class OnboardingProfileModel {
  String? phoneNumber;
  String countryCode;
  bool isPhoneVerified;

  Gender? gender;

  /// Map of platform → connected state (mock for now).
  Map<SocialPlatform, bool> connectedSocials;

  String? profileImagePath;
  String aboutMe;
  Set<String> interests;

  OnboardingProfileModel({
    this.phoneNumber,
    this.countryCode = '+977',
    this.isPhoneVerified = false,
    this.gender,
    Map<SocialPlatform, bool>? connectedSocials,
    this.profileImagePath,
    this.aboutMe = '',
    Set<String>? interests,
  })  : connectedSocials = connectedSocials ??
      {for (final p in SocialPlatform.values) p: false},
        interests = interests ?? {};

  /// Number of connected social accounts — used for trust score display.
  int get connectedSocialsCount =>
      connectedSocials.values.where((v) => v).length;

  /// Serialises this model to a JSON map for future backend submission.
  Map<String, dynamic> toJson() {
    return {
      'phoneNumber':
      phoneNumber != null ? '$countryCode$phoneNumber' : null,
      'isPhoneVerified': isPhoneVerified,
      'gender': gender?.apiValue,
      'connectedSocials': connectedSocials.entries
          .where((e) => e.value)
          .map((e) => e.key.name)
          .toList(),
      'profileImagePath': profileImagePath,
      'aboutMe': aboutMe,
      'interests': interests.toList(),
    };
  }
}

/// Display metadata for each [SocialPlatform] — icon, label, brand color.
class SocialPlatformInfo {
  final String label;
  final String iconAsset;

  const SocialPlatformInfo({required this.label, required this.iconAsset});
}

/// Display metadata for each interest chip in Profile Setup.
///
/// IMPORTANT: this list must exactly match `PREDEFINED_INTERESTS` in
/// `backend/apps/users/models.py`. The backend's `SaveInterestsSerializer`
/// rejects any name not in that list with a 400 error, so the two lists
/// have been kept in sync here.
const List<String> kAvailableInterests = [
  'Hiking',
  'Futsal',
  'Board Games',
  'Book Club',
  'Photography',
  'Cooking',
  'Travel',
  'Music',
  'Gaming',
  'Yoga',
  'Language',
  'Treks',
];
