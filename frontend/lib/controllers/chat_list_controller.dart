import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../services/inbox_socket_service.dart';

enum ChatListStatus { idle, loading, success, error }

/// Controller for the Chat List ("Messages") screen. Loads real
/// conversations from `GET /api/chat/` via [ChatService], then keeps them
/// live via [InboxSocketService] (`ws/inbox/`) — no manual refresh needed
/// when a message arrives in any of the user's chats.
class ChatListController extends ChangeNotifier {
  ChatListStatus _status = ChatListStatus.idle;
  ChatListStatus get status => _status;
  bool get isLoading => _status == ChatListStatus.loading;

  String? _error;
  String? get error => _error;

  List<ChatPreviewModel> _chats = [];
  List<ChatPreviewModel> get chats => _chats;

  int? _currentUserId;
  int? get currentUserId => _currentUserId;

  String _query = '';
  String get query => _query;

  InboxSocketService? _inboxSocket;

  /// Client-side filter by name — the backend has no `?search=` param on
  /// `ChatListView`, and the list is small enough per-user that filtering
  /// the already-fetched conversations is simplest.
  List<ChatPreviewModel> get filteredChats {
    if (_query.trim().isEmpty) return _chats;
    final q = _query.toLowerCase();
    return _chats
        .where((c) => c.otherUserFullName.toLowerCase().contains(q))
        .toList();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  Future<void> loadChats() async {
    _status = ChatListStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _currentUserId ??= await ChatService.instance.getCurrentUserId();
      _chats = await ChatService.instance.fetchChats();
      _status = ChatListStatus.success;
      unawaited(_connectInboxSocket());
    } on ApiException catch (e) {
      _error = e.message;
      _status = ChatListStatus.error;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
      _status = ChatListStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _connectInboxSocket() async {
    if (_inboxSocket != null) return; // already connected/connecting

    final token = await ChatService.instance.getAccessToken();
    if (token == null || token.isEmpty) return;

    _inboxSocket = InboxSocketService(accessToken: token);
    _inboxSocket!.events.listen(_handleInboxEvent);
    _inboxSocket!.connect();
  }

  void _handleInboxEvent(Map<String, dynamic> event) {
    if (event['type'] != 'chat_preview_update') return;

    final chatId = event['chat_id'] as int?;
    if (chatId == null) return;

    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index == -1) {
      // A brand-new chat we don't have yet (first message ever from a new
      // contact) — simplest correct handling is a one-off re-fetch just
      // for this case, since we don't have enough info (name, avatar) to
      // synthesize a full row from the socket event alone.
      loadChats();
      return;
    }

    final senderId = event['sender_id'] as int?;
    final isMine = senderId != null && senderId == _currentUserId;
    final timestamp = DateTime.tryParse(event['timestamp']?.toString() ?? '') ??
        DateTime.now();

    final existing = _chats[index];
    final updated = existing.copyWith(
      latestMessage: LatestMessagePreview(
        id: event['message_id'] as int? ?? existing.latestMessage?.id ?? 0,
        senderId: senderId ?? existing.latestMessage?.senderId ?? 0,
        content: event['content'] as String? ?? '',
        timestamp: timestamp,
        isRead: isMine, // our own outgoing messages start "read" for us
        messageType: event['message_type'] as String? ?? 'TEXT',
      ),
      // Only bump the unread count for messages the other person sent.
      unreadCount: isMine ? existing.unreadCount : existing.unreadCount + 1,
      updatedAt: timestamp,
    );

    // Move the updated chat to the top, matching backend ordering
    // (Chat.Meta.ordering = ["-updated_at"]).
    _chats.removeAt(index);
    _chats.insert(0, updated);
    notifyListeners();
  }

  @override
  void dispose() {
    _inboxSocket?.dispose();
    super.dispose();
  }
}