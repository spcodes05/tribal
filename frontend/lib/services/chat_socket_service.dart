import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/network/api_config.dart';

enum ChatSocketStatus { connecting, connected, disconnected, error }

/// Wraps the existing Django Channels WebSocket endpoint for a single chat
/// room: `ws/chat/<chat_id>/?token=<jwt>` (see backend/apps/chat/routing.py
/// and middleware.py — the JWT access token is passed as a query param and
/// verified server-side by `JWTAuthMiddleware`).
///
/// Responsibilities:
///   - Connect/disconnect for exactly one [chatId] at a time.
///   - Expose incoming `chat_message` broadcasts as a stream.
///   - Reconnect automatically (capped exponential backoff) on drop.
///   - Send new messages as `{"content": "..."}`, matching
///     `ChatConsumer.receive()` exactly — no new payload shape invented.
///
/// Explicitly NOT responsible for: loading history, creating chats, marking
/// messages read, or deleting them — those stay on [ChatService] (REST),
/// exactly mirroring the backend consumer's own division of labor.
class ChatSocketService {
  final int chatId;
  final String accessToken;

  ChatSocketService({required this.chatId, required this.accessToken});

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _manuallyClosed = false;

  final _statusController = StreamController<ChatSocketStatus>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<ChatSocketStatus> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<String> get errors => _errorController.stream;

  ChatSocketStatus _status = ChatSocketStatus.disconnected;
  ChatSocketStatus get status => _status;
  bool get isConnected => _status == ChatSocketStatus.connected;

  Uri _buildUri() {
    // ApiConfig.baseUrl looks like "http://10.0.2.2:8000/api" — strip the
    // trailing "/api" and swap the scheme for ws/wss to reach the ASGI app
    // mounted at /ws/chat/<id>/ (see backend/config/asgi.py).
    final httpBase = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final base = Uri.parse(httpBase);
    final wsScheme = base.scheme == 'https' ? 'wss' : 'ws';
    return base.replace(
      scheme: wsScheme,
      path: '/ws/chat/$chatId/',
      queryParameters: {'token': accessToken},
    );
  }

  void connect() {
    _manuallyClosed = false;
    _setStatus(ChatSocketStatus.connecting);

    try {
      _channel = WebSocketChannel.connect(_buildUri());
    } catch (_) {
      _scheduleReconnect();
      return;
    }

    _subscription = _channel!.stream.listen(
          (raw) {
        _reconnectAttempt = 0;
        _setStatus(ChatSocketStatus.connected);
        try {
          final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
          if (decoded['type'] == 'error') {
            _errorController
                .add(decoded['detail']?.toString() ?? 'Something went wrong.');
          } else {
            _messageController.add(decoded);
          }
        } catch (_) {
          // Ignore malformed frames rather than crashing the socket.
        }
      },
      onError: (_) {
        _setStatus(ChatSocketStatus.error);
        _scheduleReconnect();
      },
      onDone: () {
        if (!_manuallyClosed) {
          _setStatus(ChatSocketStatus.disconnected);
          _scheduleReconnect();
        }
      },
      cancelOnError: true,
    );

    // `ready` completes once the handshake succeeds (or throws on failure) —
    // used here just to confirm the "connected" status promptly.
    _channel!.ready.then((_) {
      if (!_manuallyClosed) _setStatus(ChatSocketStatus.connected);
    }).catchError((_) {
      _setStatus(ChatSocketStatus.error);
      _scheduleReconnect();
    });
  }

  /// Sends a new message over the open socket. Matches
  /// `ChatConsumer.receive()`'s expected payload exactly.
  void send(String content) {
    print("SEND CALLED");
    print("Status: $_status");
    print("Channel null: ${_channel == null}");

    if (!isConnected || _channel == null) {
      print("Socket not connected. Message NOT sent.");
      return;
    }

    print("Sending: $content");
    _channel!.sink.add(jsonEncode({'content': content}));
  }
  void _scheduleReconnect() {
    if (_manuallyClosed) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt = (_reconnectAttempt + 1).clamp(1, 6);
    final delaySeconds = _reconnectAttempt * _reconnectAttempt; // 1,4,9,16,25,36s cap
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_manuallyClosed) connect();
    });
  }

  void _setStatus(ChatSocketStatus s) {
    _status = s;
    if (!_statusController.isClosed) _statusController.add(s);
  }

  /// Closes the connection for good — call from the owning controller's
  /// `dispose()`. After this, [connect] must not be called again on the
  /// same instance; create a new [ChatSocketService] instead.
  void dispose() {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _statusController.close();
    _messageController.close();
    _errorController.close();
  }
}