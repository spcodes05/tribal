/// Models for the Events / Activities feature.

class ActivityHost {
  final int id;
  final String fullName;
  final bool isVerified;
  final String? profileImage;

  const ActivityHost({
    required this.id,
    required this.fullName,
    required this.isVerified,
    this.profileImage,
  });

  factory ActivityHost.fromJson(Map<String, dynamic> json) => ActivityHost(
    id: json['id'] as int,
    fullName: json['full_name'] as String? ?? '',
    isVerified: json['is_email_verified'] as bool? ?? false,
    profileImage: (json['profile_image'] as String?)?.isNotEmpty == true
        ? json['profile_image'] as String
        : null,
  );
}

class ActivityMemberModel {
  final int userId;
  final String fullName;
  final String? profileImage;

  const ActivityMemberModel({required this.userId, required this.fullName, this.profileImage});

  factory ActivityMemberModel.fromJson(Map<String, dynamic> json) =>
      ActivityMemberModel(
        userId: json['user_id'] as int,
        fullName: json['full_name'] as String? ?? '',
        profileImage: (json['profile_image'] as String?)?.isNotEmpty == true
            ? json['profile_image'] as String
            : null,
      );
}

/// Compact model used on home screen cards.
class ActivityCardModel {
  final int id;
  final String title;
  final String? imageUrl;
  final String location;
  final String date;
  final String time;
  final bool isWomenOnly;
  final bool isAccessible;
  final bool isFree;
  final int memberCount;
  final int maxMembers;
  final bool isFull;
  final String hostName;
  final double? distanceKm;
  final int? matchPercent;

  const ActivityCardModel({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.location,
    required this.date,
    required this.time,
    required this.isWomenOnly,
    required this.isAccessible,
    required this.isFree,
    required this.memberCount,
    required this.maxMembers,
    required this.isFull,
    required this.hostName,
    this.distanceKm,
    this.matchPercent,
  });

  factory ActivityCardModel.fromJson(Map<String, dynamic> json) =>
      ActivityCardModel(
        id: json['id'] as int,
        title: json['title'] as String,
        imageUrl: json['image_url'] as String?,
        location: json['location'] as String? ?? '',
        date: json['date'] as String? ?? '',
        time: json['time'] as String? ?? '',
        isWomenOnly: json['is_women_only'] as bool? ?? false,
        isAccessible: json['is_accessible'] as bool? ?? false,
        isFree: json['is_free'] as bool? ?? true,
        memberCount: json['member_count'] as int? ?? 0,
        maxMembers: json['max_members'] as int? ?? 20,
        isFull: json['is_full'] as bool? ?? false,
        hostName: json['host_name'] as String? ?? '',
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        matchPercent: json['match_percent'] as int?,
      );
}

/// Full model used on the activity detail screen.
class ActivityDetailModel {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final String location;
  final String meetingPoint;
  final String date;
  final String time;
  final bool isWomenOnly;
  final bool isAccessible;
  final bool isFree;
  final int memberCount;
  final int maxMembers;
  final bool isFull;
  final ActivityHost host;
  final List<ActivityMemberModel> recentMembers;
  final bool hasJoined;

  const ActivityDetailModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.location,
    required this.meetingPoint,
    required this.date,
    required this.time,
    required this.isWomenOnly,
    required this.isAccessible,
    required this.isFree,
    required this.memberCount,
    required this.maxMembers,
    required this.isFull,
    required this.host,
    required this.recentMembers,
    required this.hasJoined,
  });

  factory ActivityDetailModel.fromJson(Map<String, dynamic> json) =>
      ActivityDetailModel(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        imageUrl: json['image_url'] as String?,
        location: json['location'] as String? ?? '',
        meetingPoint: json['meeting_point'] as String? ?? '',
        date: json['date'] as String? ?? '',
        time: json['time'] as String? ?? '',
        isWomenOnly: json['is_women_only'] as bool? ?? false,
        isAccessible: json['is_accessible'] as bool? ?? false,
        isFree: json['is_free'] as bool? ?? true,
        memberCount: json['member_count'] as int? ?? 0,
        maxMembers: json['max_members'] as int? ?? 20,
        isFull: json['is_full'] as bool? ?? false,
        host: ActivityHost.fromJson(json['host'] as Map<String, dynamic>),
        recentMembers: (json['recent_members'] as List<dynamic>? ?? [])
            .map((e) => ActivityMemberModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasJoined: json['has_joined'] as bool? ?? false,
      );

  ActivityDetailModel copyWith({bool? hasJoined, int? memberCount}) =>
      ActivityDetailModel(
        id: id, title: title, description: description, imageUrl: imageUrl,
        location: location, meetingPoint: meetingPoint, date: date, time: time,
        isWomenOnly: isWomenOnly, isAccessible: isAccessible, isFree: isFree,
        memberCount: memberCount ?? this.memberCount,
        maxMembers: maxMembers, isFull: isFull, host: host,
        recentMembers: recentMembers,
        hasJoined: hasJoined ?? this.hasJoined,
      );
}

/// Notification model.
class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String body;
  final int? activityId;
  final String? activityTitle;
  final bool isRead;
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.activityId,
    this.activityTitle,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as int,
        type: json['notification_type'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        activityId: json['activity_id'] as int?,
        activityTitle: json['activity_title'] as String?,
        isRead: json['is_read'] as bool? ?? false,
        createdAt: json['created_at'] as String? ?? '',
      );
}

/// Person match model for "People You Might Vibe With".
class PersonMatchModel {
  final int id;
  final String fullName;
  final String? gender;
  final List<String> interests;
  final int? matchPercent;
  final String? profileImage;

  const PersonMatchModel({
    required this.id,
    required this.fullName,
    this.gender,
    required this.interests,
    this.matchPercent,
    this.profileImage,
  });

  factory PersonMatchModel.fromJson(Map<String, dynamic> json) =>
      PersonMatchModel(
        id: json['id'] as int,
        fullName: json['full_name'] as String? ?? '',
        gender: json['gender'] as String?,
        profileImage: (json['profile_image'] as String?)?.isNotEmpty == true
            ? json['profile_image'] as String
            : null,
        interests: (json['interests'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
            [],
        matchPercent: json['match_percent'] as int?,
      );
}

/// Lightweight model for map pins on the Explore screen.
class ActivityPinModel {
  final int id;
  final String title;
  final double latitude;
  final double longitude;
  final String location;
  final String date;
  final String time;
  final int memberCount;
  final int maxMembers;
  final bool isFree;
  final bool isWomenOnly;
  final bool isAccessible;
  final String? imageUrl;
  final List<String> tags;
  final String pinLabel;

  const ActivityPinModel({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.date,
    required this.time,
    required this.memberCount,
    required this.maxMembers,
    required this.isFree,
    required this.isWomenOnly,
    required this.isAccessible,
    this.imageUrl,
    required this.tags,
    required this.pinLabel,
  });

  factory ActivityPinModel.fromJson(Map<String, dynamic> json) =>
      ActivityPinModel(
        id: json['id'] as int,
        title: json['title'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        location: json['location'] as String? ?? '',
        date: json['date'] as String? ?? '',
        time: json['time'] as String? ?? '',
        memberCount: json['member_count'] as int? ?? 0,
        maxMembers: json['max_members'] as int? ?? 20,
        isFree: json['is_free'] as bool? ?? true,
        isWomenOnly: json['is_women_only'] as bool? ?? false,
        isAccessible: json['is_accessible'] as bool? ?? false,
        imageUrl: json['image_url'] as String?,
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        pinLabel: json['pin_label'] as String? ?? json['title'] as String,
      );
}