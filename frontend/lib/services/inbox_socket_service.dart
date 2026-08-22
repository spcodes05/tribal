import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/network/api_config.dart';

/// Wraps `ws/inbox/` — a per-user WebSocket (see
/// backend/apps/chat/consumers.py InboxConsumer) that pushes a lightweight
/// event whenever any of the user's chats gets a new message, so the Chat
/// List screen can update live without a manual refresh.
///
/// Mirrors [ChatSocketService]'s connect/reconnect pattern exactly, just
/// scoped to the user instead of a single chat room.
class InboxSocketService {
  final String accessToken;
  InboxSocketService({required this.accessToken});

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _manuallyClosed = false;

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  Uri _buildUri() {
    final httpBase = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final base = Uri.parse(httpBase);
    final wsScheme = base.scheme == 'https' ? 'wss' : 'ws';
    return base.replace(
      scheme: wsScheme,
      path: '/ws/inbox/',
      queryParameters: {'token': accessToken},
    );
  }

  void connect() {
    _manuallyClosed = false;

    try {
      _channel = WebSocketChannel.connect(_buildUri());
    } catch (_) {
      _scheduleReconnect();
      return;
    }

    _subscription = _channel!.stream.listen(
          (raw) {
        _reconnectAttempt = 0;
        try {
          final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
          _eventController.add(decoded);
        } catch (_) {
          // Ignore malformed frames.
        }
      },
      onError: (_) => _scheduleReconnect(),
      onDone: () {
        if (!_manuallyClosed) _scheduleReconnect();
      },
      cancelOnError: true,
    );
  }

  void _scheduleReconnect() {
    if (_manuallyClosed) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt = (_reconnectAttempt + 1).clamp(1, 6);
    final delaySeconds = _reconnectAttempt * _reconnectAttempt;
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_manuallyClosed) connect();
    });
  }

  void dispose() {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _eventController.close();
  }
}