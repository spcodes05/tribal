import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../core/network/token_storage.dart';
import '../models/chat_model.dart';
import 'auth_service.dart';

/// Talks to `backend/apps/chat/` via the shared [ApiClient].
///
/// Every method throws an [ApiException] on failure, same convention as
/// [RoommateService] / [EventsService].
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  Dio get _dio => ApiClient.instance.dio;

  // ── Current user id ─────────────────────────────────────────────────────
  // `AuthController.currentUser` is only populated during an active
  // login/register flow in the current session — it isn't re-fetched on a
  // cold start — so the chat feature resolves + caches its own copy here
  // via the existing `GET /api/users/me/` (AuthService.getCurrentUser())
  // rather than modifying AuthController.
  int? _cachedUserId;

  Future<int> getCurrentUserId() async {
    if (_cachedUserId != null) return _cachedUserId!;
    final me = await AuthService.instance.getCurrentUser();
    final id = int.parse(me.id);
    _cachedUserId = id;
    return id;
  }

  /// The raw JWT access token, needed to authenticate the WebSocket
  /// connection (`?token=<access>` — see backend/apps/chat/middleware.py).
  /// It's the same token [ApiClient] already attaches as a Bearer header on
  /// every REST call.
  Future<String?> getAccessToken() => TokenStorage.instance.getAccessToken();

  /// GET /api/chat/ — every conversation belonging to the current user.
  Future<List<ChatPreviewModel>> fetchChats() async {
    try {
      final response = await _dio.get(ApiConfig.chatList);
      final data = response.data as List<dynamic>;
      return data
          .map((e) => ChatPreviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /api/chat/<chat_id>/ — full message history, oldest first.
  /// Not paginated — `ChatMessageListView` returns the entire thread in one
  /// call (no `DEFAULT_PAGINATION_CLASS` configured on the backend).
  Future<List<MessageModel>> fetchMessages(int chatId) async {
    try {
      final response = await _dio.get(ApiConfig.chatMessages(chatId));
      final data = response.data as List<dynamic>;
      return data
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/chat/start/ — returns the existing chat with [userId], or
  /// creates one (`Chat.get_or_create_chat` is idempotent). Safe to call
  /// every time "Start Chat" is tapped — the user never manually creates a
  /// duplicate conversation.
  Future<ChatPreviewModel> startChat(int userId) async {
    try {
      final response = await _dio.post(
        ApiConfig.chatStart,
        data: {'user_id': userId},
      );
      return ChatPreviewModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /api/chat/<chat_id>/send/ — REST fallback used only when the
  /// WebSocket connection isn't open (see [ChatSocketService]); the socket
  /// is the primary send path since it also broadcasts to the other
  /// participant in real time.
  Future<MessageModel> sendMessage(int chatId, String content) async {
    try {
      final response = await _dio.post(
        ApiConfig.chatSend(chatId),
        data: {'content': content},
      );
      return MessageModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// PATCH /api/chat/message/<message_id>/read/
  Future<void> markMessageRead(int messageId) async {
    try {
      await _dio.patch(ApiConfig.messageRead(messageId));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// DELETE /api/chat/message/<message_id>/
  Future<void> deleteMessage(int messageId) async {
    try {
      await _dio.delete(ApiConfig.messageDelete(messageId));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}