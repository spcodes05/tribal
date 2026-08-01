/// Models for the "Your Tribe Status" and "Other User Profile" screens.
/// Mirrors backend/apps/users/serializers.py (PublicUserProfileSerializer)
/// and the TribeStatusView / PublicProfileView response shapes exactly.

/// The common "person" fields shared by both the logged-in user's own
/// profile and another user's public profile.
class ProfileCore {
  final int id;
  final String fullName;
  final String? username;
  final String? profileImage;
  final String? bio;
  final int? age;
  final String? occupation;
  final String? university;
  final String? location;
  final String? gender;
  final List<String> interests;
  final bool isEmailVerified;

  const ProfileCore({
    required this.id,
    required this.fullName,
    this.username,
    this.profileImage,
    this.bio,
    this.age,
    this.occupation,
    this.university,
    this.location,
    this.gender,
    this.interests = const [],
    this.isEmailVerified = false,
  });

  factory ProfileCore.fromJson(Map<String, dynamic> json) {
    String? nonEmpty(String? v) => (v != null && v.trim().isNotEmpty) ? v : null;
    return ProfileCore(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      username: nonEmpty(json['username'] as String?),
      profileImage: nonEmpty(json['profile_image'] as String?),
      bio: nonEmpty(json['bio'] as String?),
      age: json['age'] as int?,
      occupation: nonEmpty(json['occupation'] as String?),
      university: nonEmpty(json['university'] as String?),
      location: nonEmpty(json['location'] as String?),
      gender: json['gender'] as String?,
      interests: (json['interests'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
    );
  }

  /// Up to 2 initials for the avatar fallback, same convention as ChatPreviewModel.
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

/// Real, computed stats for "Your Tribe Status". Only counts backed by an
/// actual model are included — no fabricated "Friends Made"/"Communities"
/// numbers (Tribal has no friendship/community model).
class TribeStatsModel {
  final int activitiesJoined;
  final int eventsHosted;
  final int roommateMatches;
  final int peopleMet;
  final int chatStreak;

  const TribeStatsModel({
    required this.activitiesJoined,
    required this.eventsHosted,
    required this.roommateMatches,
    required this.peopleMet,
    required this.chatStreak,
  });

  factory TribeStatsModel.fromJson(Map<String, dynamic> json) => TribeStatsModel(
    activitiesJoined: json['activities_joined'] as int? ?? 0,
    eventsHosted: json['events_hosted'] as int? ?? 0,
    roommateMatches: json['roommate_matches'] as int? ?? 0,
    peopleMet: json['people_met'] as int? ?? 0,
    chatStreak: json['chat_streak'] as int? ?? 0,
  );
}

class TimelineEntryModel {
  final String type; // 'joined_activity' | 'hosted_activity' | 'roommate_match'
  final String title;
  final DateTime date;
  final String? location;
  final int? peopleCount;
  final String? imageUrl;

  const TimelineEntryModel({
    required this.type,
    required this.title,
    required this.date,
    this.location,
    this.peopleCount,
    this.imageUrl,
  });

  factory TimelineEntryModel.fromJson(Map<String, dynamic> json) => TimelineEntryModel(
    type: json['type'] as String? ?? '',
    title: json['title'] as String? ?? '',
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    location: json['location'] as String?,
    peopleCount: json['people_count'] as int?,
    imageUrl: (json['image_url'] as String?)?.isNotEmpty == true
        ? json['image_url'] as String
        : null,
  );
}

class AchievementModel {
  final String key;
  final String label;
  final String description;
  final bool earned;

  const AchievementModel({
    required this.key,
    required this.label,
    required this.description,
    required this.earned,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) => AchievementModel(
    key: json['key'] as String? ?? '',
    label: json['label'] as String? ?? '',
    description: json['description'] as String? ?? '',
    earned: json['earned'] as bool? ?? false,
  );
}

/// A compact public event summary (title/date/location only) used in
/// "Other User Profile → Tribe Activity". No private data included.
class PublicEventSummary {
  final String title;
  final String date;
  final String location;

  const PublicEventSummary({required this.title, required this.date, required this.location});

  factory PublicEventSummary.fromJson(Map<String, dynamic> json) => PublicEventSummary(
    title: json['title'] as String? ?? '',
    date: json['date'] as String? ?? '',
    location: json['location'] as String? ?? '',
  );
}

/// Full response of GET /api/users/me/tribe-status/
class TribeStatusModel {
  final ProfileCore profile;
  final TribeStatsModel stats;
  final dynamic upcomingActivityJson; // raw json, parsed into ActivityCardModel by the caller
  final List<TimelineEntryModel> recentTimeline;
  final List<AchievementModel> achievements;

  const TribeStatusModel({
    required this.profile,
    required this.stats,
    required this.upcomingActivityJson,
    required this.recentTimeline,
    required this.achievements,
  });

  factory TribeStatusModel.fromJson(Map<String, dynamic> json) => TribeStatusModel(
    profile: ProfileCore.fromJson(json['profile'] as Map<String, dynamic>),
    stats: TribeStatsModel.fromJson(json['stats'] as Map<String, dynamic>),
    upcomingActivityJson: json['upcoming_activity'],
    recentTimeline: (json['recent_timeline'] as List<dynamic>? ?? [])
        .map((e) => TimelineEntryModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    achievements: (json['achievements'] as List<dynamic>? ?? [])
        .map((e) => AchievementModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Full response of GET /api/users/<id>/profile/
class PublicProfileModel {
  final ProfileCore core;
  final List<String> mutualInterests;
  final int? compatibilityPercent;
  final int activitiesJoined;
  final List<PublicEventSummary> recentPublicEvents;
  final bool isBlockedByMe;

  const PublicProfileModel({
    required this.core,
    required this.mutualInterests,
    this.compatibilityPercent,
    required this.activitiesJoined,
    required this.recentPublicEvents,
    required this.isBlockedByMe,
  });

  factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
    final tribeActivity = json['tribe_activity'] as Map<String, dynamic>? ?? {};
    return PublicProfileModel(
      core: ProfileCore.fromJson(json['profile'] as Map<String, dynamic>),
      mutualInterests: (json['mutual_interests'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      compatibilityPercent: json['compatibility_percent'] as int?,
      activitiesJoined: tribeActivity['activities_joined'] as int? ?? 0,
      recentPublicEvents: (tribeActivity['recent_public_events'] as List<dynamic>? ?? [])
          .map((e) => PublicEventSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      isBlockedByMe: json['is_blocked_by_me'] as bool? ?? false,
    );
  }
}

/// Extra context passed via GoRouter `extra` when navigating to
/// [otherUserProfile] from a screen that already knows a match percentage
/// (e.g. the VibeScore on "People You Might Vibe With"). This lets the
/// profile screen show a compatibility badge even when no RoommateMatch
/// row exists yet between the two users — without ever fabricating a
/// number of its own.
class OtherProfileNavArgs {
  final int? fallbackMatchPercent;
  const OtherProfileNavArgs({this.fallbackMatchPercent});
}