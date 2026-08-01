import 'package:flutter/material.dart';

/// Models for the Chat feature, backed by `backend/apps/chat/`.
///
/// Field names/shapes mirror the Django REST serializers exactly
/// (see backend/apps/chat/serializers.py) so `fromJson` never has to guess:
///   - [MessageModel]        <- MessageSerializer
///   - [LatestMessagePreview] <- the `latest_message` dict on ChatPreviewSerializer
///   - [ChatPreviewModel]    <- ChatPreviewSerializer
///
/// NOTE: the backend has no online/last-seen status and no message "type"
/// (text only, no location/attachment) — do not invent fields for either;
/// see the integration notes in chat_tile.dart / chat_screen.dart.

/// A single message inside a conversation.
class MessageModel {
  final int id;
  final int chatId;
  final int senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? editedAt;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.editedAt,
  });

  /// From `GET /api/chat/<id>/` or `POST /api/chat/<id>/send/`
  /// (MessageSerializer).
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      chatId: json['chat'] as int,
      senderId: json['sender_id'] as int,
      content: json['content'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
      isRead: json['is_read'] as bool? ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String).toLocal()
          : null,
    );
  }

  /// From a WebSocket `chat_message` broadcast (see
  /// backend/apps/chat/consumers.py `ChatConsumer.receive`), which uses a
  /// slightly different key set (`message_id` instead of `id`, no
  /// `is_read`/`edited_at`) than the REST serializer above.
  factory MessageModel.fromSocketEvent(Map<String, dynamic> json) {
    return MessageModel(
      id: json['message_id'] as int,
      chatId: json['chat_id'] as int,
      senderId: json['sender_id'] as int,
      content: json['content'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
      isRead: false,
    );
  }

  MessageModel copyWith({bool? isRead}) {
    return MessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      content: content,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      editedAt: editedAt,
    );
  }

  String get formattedTime => ChatTimeFormat.time(timestamp);
}

/// Compact "latest message" preview embedded in a [ChatPreviewModel]
/// (the `latest_message` dict from `ChatPreviewSerializer.get_latest_message`).
class LatestMessagePreview {
  final int id;
  final int senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  const LatestMessagePreview({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory LatestMessagePreview.fromJson(Map<String, dynamic> json) {
    return LatestMessagePreview(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      content: json['content'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}

/// One row on the Chat List screen — mirrors `ChatPreviewSerializer`
/// exactly.
///
/// NOTE: the backend does not expose an online/last-seen status for the
/// other participant, so there is intentionally no `isOnline` field here.
class ChatPreviewModel {
  final int id;
  final String otherUserFullName;
  final String? otherUserProfileImage;
  final LatestMessagePreview? latestMessage;
  final int unreadCount;
  final DateTime updatedAt;

  const ChatPreviewModel({
    required this.id,
    required this.otherUserFullName,
    this.otherUserProfileImage,
    this.latestMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ChatPreviewModel.fromJson(Map<String, dynamic> json) {
    final rawName = json['other_user_full_name'] as String?;
    return ChatPreviewModel(
      id: json['id'] as int,
      otherUserFullName:
      (rawName != null && rawName.trim().isNotEmpty) ? rawName : 'Tribal User',
      otherUserProfileImage: json['other_user_profile_image'] as String?,
      latestMessage: json['latest_message'] != null
          ? LatestMessagePreview.fromJson(
          json['latest_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  /// Up to 2 initials derived from the display name, e.g. "Anisha Tamang" -> "AT".
  String get initials {
    final parts = otherUserFullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Deterministic avatar color derived from the chat id — the backend has
  /// no color/avatar concept, so this just keeps each contact visually
  /// distinct instead of every avatar looking identical.
  Color get avatarColor {
    const palette = [
      Color(0xFFC0392B),
      Color(0xFF2E6F95),
      Color(0xFF7A4FB5),
      Color(0xFF1F8A5F),
      Color(0xFFB5762F),
      Color(0xFF3B6E8F),
    ];
    return palette[id % palette.length];
  }

  String get lastMessagePreview =>
      latestMessage?.content ?? 'Say hi to start the conversation.';

  String get formattedTimestamp =>
      ChatTimeFormat.listTimestamp(latestMessage?.timestamp ?? updatedAt);
}

/// Lightweight args passed via GoRouter `extra` when navigating into a
/// conversation — enough to render the AppBar header instantly without an
/// extra network round trip (the message-list endpoint returns messages
/// only, no participant info — see ChatMessageListView).
class ChatConversationArgs {
  final int chatId;
  final String otherUserFullName;
  final String? otherUserProfileImage;

  const ChatConversationArgs({
    required this.chatId,
    required this.otherUserFullName,
    this.otherUserProfileImage,
  });
}

/// Small manual date/time formatter — kept dependency-free (no `intl`
/// package in this project) but mirrors a WhatsApp-style list format:
/// today -> "2:45 PM", yesterday -> "Yesterday", this week -> "Mon",
/// older -> "Jul 20".
class ChatTimeFormat {
  ChatTimeFormat._();

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String time(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  static String listTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return time(dt);
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return _weekdays[dt.weekday - 1];
    return '${_months[dt.month - 1]} ${dt.day}';
  }
}