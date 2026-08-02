import 'roommate_profile_model.dart';

/// Mirrors `RoommateProfileSummarySerializer` exactly (see
/// backend/apps/roommate/serializers.py). Used only inside match results —
/// NOT the same as the write-side `RoommateQuizModel`.
///
/// NOTE: the backend does not return age, location, or a verification
/// badge for a match — those were mockup-only fields. Do not invent them
/// here; `RoommateMatchCard` has been updated to treat them as optional.
class RoommateProfileSummary {
  final int id;
  final int userId;
  final String? userEmail;
  final String? userFullName;
  final String? userProfileImage;
  final int budgetMin;
  final int budgetMax;
  final String sleepScheduleRaw;
  final String wakeTime;
  final String smokingRaw;
  final String drinkingRaw;
  final int cleanliness;
  final int noiseLevel;
  final String guestsPreferenceRaw;
  final String foodPreferenceRaw;
  final String petsRaw;
  final String studyHabitRaw;
  final List<String> interestNames;
  final String roomTypePreferenceRaw;

  const RoommateProfileSummary({
    required this.id,
    required this.userId,
    this.userEmail,
    this.userFullName,
    this.userProfileImage,
    required this.budgetMin,
    required this.budgetMax,
    required this.sleepScheduleRaw,
    required this.wakeTime,
    required this.smokingRaw,
    required this.drinkingRaw,
    required this.cleanliness,
    required this.noiseLevel,
    required this.guestsPreferenceRaw,
    required this.foodPreferenceRaw,
    required this.petsRaw,
    required this.studyHabitRaw,
    required this.interestNames,
    required this.roomTypePreferenceRaw,
  });

  factory RoommateProfileSummary.fromJson(Map<String, dynamic> json) {
    return RoommateProfileSummary(
      id: json['id'] as int,
      userId: json['user'] as int,
      userEmail: json['user_email'] as String?,
      userFullName: json['user_full_name'] as String?,
      userProfileImage: (json['user_profile_image'] as String?)?.isNotEmpty == true
          ? json['user_profile_image'] as String
          : null,
      budgetMin: json['budget_min'] as int,
      budgetMax: json['budget_max'] as int,
      sleepScheduleRaw: json['sleep_schedule'] as String? ?? '',
      wakeTime: json['wake_time'] as String? ?? '',
      smokingRaw: json['smoking'] as String? ?? '',
      drinkingRaw: json['drinking'] as String? ?? '',
      cleanliness: json['cleanliness'] as int? ?? 0,
      noiseLevel: json['noise_level'] as int? ?? 0,
      guestsPreferenceRaw: json['guests_preference'] as String? ?? '',
      foodPreferenceRaw: json['food_preference'] as String? ?? '',
      petsRaw: json['pets'] as String? ?? '',
      studyHabitRaw: json['study_habit'] as String? ?? '',
      interestNames: ((json['interest_details'] as List<dynamic>?) ?? [])
          .map((e) => (e as Map<String, dynamic>)['name'].toString())
          .toList(),
      roomTypePreferenceRaw: json['room_type_preference'] as String? ?? '',
    );
  }

  String get sleepScheduleLabel =>
      SleepScheduleApi.fromApiValue(sleepScheduleRaw).label;
  String get smokingLabel => SmokingApi.fromApiValue(smokingRaw).label;
  String get foodLabel => FoodApi.fromApiValue(foodPreferenceRaw).label;
}

/// Mirrors `ScoreBreakdownSerializer` exactly.
class RoommateScoreBreakdown {
  final double cleanliness;
  final double budget;
  final double sleepSchedule;
  final double noiseLevel;
  final double smoking;
  final double guests;
  final double interests;
  final double studyHabit;
  final double food;
  final double drinking;

  const RoommateScoreBreakdown({
    required this.cleanliness,
    required this.budget,
    required this.sleepSchedule,
    required this.noiseLevel,
    required this.smoking,
    required this.guests,
    required this.interests,
    required this.studyHabit,
    required this.food,
    required this.drinking,
  });

  factory RoommateScoreBreakdown.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
    return RoommateScoreBreakdown(
      cleanliness: asDouble(json['cleanliness']),
      budget: asDouble(json['budget']),
      sleepSchedule: asDouble(json['sleep_schedule']),
      noiseLevel: asDouble(json['noise_level']),
      smoking: asDouble(json['smoking']),
      guests: asDouble(json['guests']),
      interests: asDouble(json['interests']),
      studyHabit: asDouble(json['study_habit']),
      food: asDouble(json['food']),
      drinking: asDouble(json['drinking']),
    );
  }
}

/// Mirrors `RoommateMatchResultSerializer` exactly — one item in the array
/// returned by `GET /api/roommate/find/`.
class RoommateMatchResult {
  final int userId;
  final RoommateProfileSummary profile;
  final double score;
  final RoommateScoreBreakdown breakdown;
  final bool dealBreaker;
  final List<String> dealBreakerReasons;

  const RoommateMatchResult({
    required this.userId,
    required this.profile,
    required this.score,
    required this.breakdown,
    this.dealBreaker = false,
    this.dealBreakerReasons = const [],
  });

  factory RoommateMatchResult.fromJson(Map<String, dynamic> json) {
    return RoommateMatchResult(
      userId: json['user_id'] as int,
      profile: RoommateProfileSummary.fromJson(
        json['profile'] as Map<String, dynamic>,
      ),
      score: (json['score'] as num).toDouble(),
      breakdown: RoommateScoreBreakdown.fromJson(
        json['breakdown'] as Map<String, dynamic>,
      ),
      dealBreaker: json['deal_breaker'] as bool? ?? false,
      dealBreakerReasons: ((json['deal_breaker_reasons'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  /// Falls back to email, never fabricates a name.
  String get displayName {
    final name = profile.userFullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return profile.userEmail ?? 'Tribal User';
  }

  /// Real tags derived from the actual profile fields the backend sends
  /// (sleep schedule, food, smoking) — same labels used in the quiz.
  List<String> get displayTags => [
    profile.sleepScheduleLabel,
    profile.foodLabel,
    profile.smokingLabel,
  ];
}