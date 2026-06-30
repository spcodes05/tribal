/// Data model representing an authenticated TRIBAL user.
///
/// Mirrors the shape returned by the Django backend:
///   - RegisterView / LoginView's "user" object
///   - MeView (UserDetailSerializer) for the full profile
///
/// Backend fields are snake_case (full_name, is_email_verified, ...);
/// this model exposes them as camelCase Dart fields via [fromJson].
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? gender;
  final List<String> interests;
  final bool isEmailVerified;
  final bool isOnboardingComplete;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.gender,
    this.interests = const [],
    this.isEmailVerified = false,
    this.isOnboardingComplete = false,
  });

  /// Creates a UserModel from a JSON map.
  ///
  /// Handles both response shapes:
  ///   - Register/Login: {"id":.., "full_name":.., "email":.., "is_email_verified":..}
  ///   - Me (full detail): adds "gender", "interests": [{"id":.., "name":..}], "is_onboarding_complete"
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      gender: json['gender'] as String?,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e is Map ? e['name'].toString() : e.toString())
              .toList() ??
          const [],
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      isOnboardingComplete: json['is_onboarding_complete'] as bool? ?? false,
    );
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? gender,
    List<String>? interests,
    bool? isEmailVerified,
    bool? isOnboardingComplete,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      interests: interests ?? this.interests,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, fullName: $fullName, email: $email)';
}
