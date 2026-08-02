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
  final String? username;
  final String? profileImage;
  final String? bio;
  final int? age;
  final String? occupation;
  final String? university;
  final String? location;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.gender,
    this.interests = const [],
    this.isEmailVerified = false,
    this.isOnboardingComplete = false,
    this.username,
    this.profileImage,
    this.bio,
    this.age,
    this.occupation,
    this.university,
    this.location,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? nonEmpty(String? v) => (v != null && v.trim().isNotEmpty) ? v : null;
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
      username: nonEmpty(json['username'] as String?),
      profileImage: nonEmpty(json['profile_image'] as String?),
      bio: nonEmpty(json['bio'] as String?),
      age: json['age'] as int?,
      occupation: nonEmpty(json['occupation'] as String?),
      university: nonEmpty(json['university'] as String?),
      location: nonEmpty(json['location'] as String?),
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
    String? username,
    String? profileImage,
    String? bio,
    int? age,
    String? occupation,
    String? university,
    String? location,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      interests: interests ?? this.interests,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      age: age ?? this.age,
      occupation: occupation ?? this.occupation,
      university: university ?? this.university,
      location: location ?? this.location,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, fullName: $fullName, email: $email)';
}