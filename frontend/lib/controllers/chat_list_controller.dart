import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

enum ChatListStatus { idle, loading, success, error }

/// Controller for the Chat List ("Messages") screen. Loads real
/// conversations from `GET /api/chat/` via [ChatService].
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
}