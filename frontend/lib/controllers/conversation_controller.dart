import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../services/chat_socket_service.dart';

enum ConversationStatus { idle, loading, success, error }

/// Controller for a single conversation (ChatScreen).
///
/// Loads history over REST (`GET /api/chat/<id>/`), then opens a WebSocket
/// (`ws/chat/<id>/`) for real-time delivery — reusing the existing Django
/// Channels backend exactly as-is (see backend/apps/chat/consumers.py).
///
/// Sending prefers the socket (so the message round-trips through the same
/// broadcast the other participant receives); if the socket isn't
/// connected, it falls back to the REST send endpoint so the user is never
/// blocked from sending a message.
class ConversationController extends ChangeNotifier {
  final int chatId;
  ConversationController({required this.chatId});

  ConversationStatus _status = ConversationStatus.idle;
  ConversationStatus get status => _status;
  bool get isLoading => _status == ConversationStatus.loading;

  String? _error;
  String? get error => _error;

  final List<MessageModel> _messages = [];
  List<MessageModel> get messages => List.unmodifiable(_messages);

  int? _currentUserId;
  int? get currentUserId => _currentUserId;
  bool isMine(MessageModel m) =>
      _currentUserId != null && m.senderId == _currentUserId;

  bool _isSending = false;
  bool get isSending => _isSending;

  ChatSocketService? _socket;
  ChatSocketStatus _socketStatus = ChatSocketStatus.disconnected;
  ChatSocketStatus get socketStatus => _socketStatus;

  StreamSubscription? _socketMsgSub;
  StreamSubscription? _socketStatusSub;
  StreamSubscription? _socketErrorSub;

  // Temp ids (negative, decreasing) for optimistically-appended outgoing
  // messages, queued FIFO so the next matching broadcast for *my own*
  // message reconciles with the right bubble instead of duplicating it.
  int _tempIdCounter = 0;
  final List<int> _pendingOptimisticIds = [];

  Future<void> initialize() async {
    _status = ConversationStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _currentUserId = await ChatService.instance.getCurrentUserId();
      final history = await ChatService.instance.fetchMessages(chatId);
      _messages
        ..clear()
        ..addAll(history);
      _status = ConversationStatus.success;
      notifyListeners();

      unawaited(_markIncomingAsRead());
      await _connectSocket();
    } on ApiException catch (e) {
      _error = e.message;
      _status = ConversationStatus.error;
      notifyListeners();
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
      _status = ConversationStatus.error;
      notifyListeners();
    }
  }

  Future<void> _connectSocket() async {
    print('=== CONNECTING CHAT SOCKET ===');

    final token = await ChatService.instance.getAccessToken();

    print('Token exists: ${token != null && token.isNotEmpty}');

    if (token == null || token.isEmpty) {
      print('NO ACCESS TOKEN');
      return;
    }

    _socket = ChatSocketService(
      chatId: chatId,
      accessToken: token,
    );

    print('Chat ID: $chatId');

    _socketStatusSub = _socket!.statusStream.listen((s) {
      print('SOCKET STATUS: $s');
      _socketStatus = s;
      notifyListeners();
    });

    _socketMsgSub = _socket!.messages.listen((event) {
      print('SOCKET MESSAGE RECEIVED: $event');
      _handleIncomingSocketEvent(event);
    });

    _socketErrorSub = _socket!.errors.listen((msg) {
      print('SOCKET ERROR: $msg');
      _error = msg;
      notifyListeners();
    });

    print('CALLING SOCKET CONNECT');
    _socket!.connect();
  }

  void _handleIncomingSocketEvent(Map<String, dynamic> event) {
    switch (event['type']) {
      case 'chat_message':
        _handleChatMessageEvent(event);
        break;
      case 'live_location_update':
        _handleLiveLocationUpdateEvent(event);
        break;
      case 'live_location_ended':
        _handleLiveLocationEndedEvent(event);
        break;
      default:
        return;
    }
  }

  void _handleChatMessageEvent(Map<String, dynamic> event) {
    final incoming = MessageModel.fromSocketEvent(event);

    // Already have this exact message (e.g. a duplicate broadcast) — skip.
    if (_messages.any((m) => m.id == incoming.id)) return;

    final isMineMessage = incoming.senderId == _currentUserId;

    if (isMineMessage && _pendingOptimisticIds.isNotEmpty) {
      // Reconcile with the optimistic bubble we already showed instead of
      // appending a duplicate.
      final tempId = _pendingOptimisticIds.removeAt(0);
      _replaceMessage(tempId, incoming);
    } else {
      _messages.add(incoming);
      if (!isMineMessage) {
        ChatService.instance.markMessageRead(incoming.id).catchError((_) {});
      }
    }

    notifyListeners();
  }

  // Mutates the existing live-location card message's coordinates in
  // place — the backend never sends a new Message for coordinate updates
  // (see apps/safety/views.py UserLocationUpdateView), so this must not
  // append to _messages.
  void _handleLiveLocationUpdateEvent(Map<String, dynamic> event) {
    final liveLocationId = event['live_location_id'] as int?;
    if (liveLocationId == null) return;

    final idx = _messages.indexWhere((m) => m.liveLocationId == liveLocationId);
    if (idx == -1) return;

    final lat = double.tryParse(event['latitude']?.toString() ?? '');
    final lng = double.tryParse(event['longitude']?.toString() ?? '');
    if (lat == null || lng == null) return;

    _messages[idx] = _messages[idx].copyWith(
      liveLocationLatitude: lat,
      liveLocationLongitude: lng,
    );
    notifyListeners();
  }

  void _handleLiveLocationEndedEvent(Map<String, dynamic> event) {
    final liveLocationId = event['live_location_id'] as int?;
    if (liveLocationId == null) return;

    final idx = _messages.indexWhere((m) => m.liveLocationId == liveLocationId);
    if (idx == -1) return;

    _messages[idx] = _messages[idx].copyWith(liveLocationStatus: 'ENDED');
    notifyListeners();
  }

  void _replaceMessage(int oldId, MessageModel replacement) {
    final idx = _messages.indexWhere((m) => m.id == oldId);
    if (idx != -1) {
      _messages[idx] = replacement;
    } else {
      _messages.add(replacement);
    }
  }

  Future<void> _markIncomingAsRead() async {
    final unread = _messages.where((m) => !isMine(m) && !m.isRead).toList();
    for (final m in unread) {
      try {
        await ChatService.instance.markMessageRead(m.id);
        final idx = _messages.indexWhere((x) => x.id == m.id);
        if (idx != -1) _messages[idx] = _messages[idx].copyWith(isRead: true);
      } catch (_) {
        // Best-effort — a failed read receipt shouldn't block the chat.
      }
    }
    notifyListeners();
  }

  Future<bool> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || _isSending) return false;

    _isSending = true;
    notifyListeners();

    final tempId = --_tempIdCounter;
    final optimistic = MessageModel(
      id: tempId,
      chatId: chatId,
      senderId: _currentUserId ?? -1,
      content: trimmed,
      timestamp: DateTime.now(),
      isRead: false,
    );
    _messages.add(optimistic);
    notifyListeners();

    try {
      if (_socket != null && _socket!.isConnected) {
        // The server broadcasts this back to both participants (including
        // us) — see _handleIncomingSocketEvent, which reconciles it with
        // this optimistic bubble instead of appending a duplicate.
        _pendingOptimisticIds.add(tempId);
        _socket!.send(trimmed);
      } else {
        // Socket unavailable — fall back to the REST endpoint and replace
        // the optimistic bubble with the server-confirmed message.
        final sent = await ChatService.instance.sendMessage(chatId, trimmed);
        _replaceMessage(tempId, sent);
      }
      return true;
    } on ApiException catch (e) {
      _messages.removeWhere((m) => m.id == tempId);
      _error = e.message;
      return false;
    } catch (_) {
      _messages.removeWhere((m) => m.id == tempId);
      _error = 'Failed to send message. Please try again.';
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void retry() => initialize();

  @override
  void dispose() {
    _socketMsgSub?.cancel();
    _socketStatusSub?.cancel();
    _socketErrorSub?.cancel();
    _socket?.dispose();
    super.dispose();
  }
}