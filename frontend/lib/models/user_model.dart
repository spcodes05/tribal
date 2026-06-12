/// Data model representing an authenticated TRIBAL user.
///
/// Designed for future backend integration: all fields map 1-to-1
/// with the expected API response shape from the NestJS auth service.
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? photoUrl;
  final String? phone;
  final double trustScore;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.photoUrl,
    this.phone,
    this.trustScore = 0.0,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    required this.createdAt,
  });

  /// Creates a UserModel from a JSON map (API response).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      phone: json['phone'] as String?,
      trustScore: (json['trustScore'] as num?)?.toDouble() ?? 0.0,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Serialises this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'photoUrl': photoUrl,
      'phone': phone,
      'trustScore': trustScore,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Returns a copy of this model with updated fields.
  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? photoUrl,
    String? phone,
    double? trustScore,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      trustScore: trustScore ?? this.trustScore,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'UserModel(id: $id, fullName: $fullName, email: $email)';
}
