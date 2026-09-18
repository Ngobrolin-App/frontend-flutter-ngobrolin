import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:developer' as developer;

class SocketService {
  IO.Socket? _socket;

  // Registry of handlers so they are re-applied to any new socket instance
  // (reconnect / re-init must not orphan screen-registered listeners).
  final Map<String, List<void Function(dynamic)>> _handlers = {};

  bool get isConnected => _socket?.connected ?? false;

  void connect({required String url, String? token}) {
    developer.log('SocketService: connecting to $url', name: 'SocketService');

    final opts = IO.OptionBuilder()
        .setTransports(['websocket'])
        .setPath('/socket.io')
        .enableAutoConnect()
        .setTimeout(10000)
        .setExtraHeaders(
          token != null ? {'Authorization': 'Bearer $token'} : {},
        )
        .build();

    _socket = IO.io(url, opts);

    _socket?.on(
      'connecting',
      (_) => developer.log('Socket connecting...', name: 'SocketService'),
    );
    _socket?.on(
      'connect',
      (_) => developer.log('Socket connected', name: 'SocketService'),
    );
    _socket?.on(
      'connect_error',
      (err) =>
          developer.log('Socket connect_error: $err', name: 'SocketService'),
    );
    _socket?.on(
      'error',
      (err) => developer.log('Socket error: $err', name: 'SocketService'),
    );
    _socket?.on(
      'disconnect',
      (_) => developer.log('Socket disconnect', name: 'SocketService'),
    );
    _socket?.on(
      'reconnect',
      (attempt) =>
          developer.log('Socket reconnect: $attempt', name: 'SocketService'),
    );

    // Re-apply registered handlers on the new socket instance
    _handlers.forEach((event, handlers) {
      for (final handler in handlers) {
        _socket?.on(event, handler);
      }
    });
  }

  void on(String event, void Function(dynamic data) handler) {
    final list = _handlers.putIfAbsent(event, () => []);
    if (!list.contains(handler)) list.add(handler);
    _socket?.on(event, handler);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void off(String event, [dynamic handler]) {
    if (handler != null) {
      _handlers[event]?.remove(handler);
    } else {
      _handlers.remove(event);
    }
    _socket?.off(event, handler);
  }

  // Remove ALL handlers (core + screen-registered). Use only on full re-init.
  void clearListeners() {
    _handlers.clear();
    _socket?.clearListeners();
  }

  void joinConversationSocket(String conversationId) {
    _socket?.emit('join_conversation', {'conversationId': conversationId});
  }

  void leaveConversationSocket(String conversationId) {
    _socket?.emit('leave_conversation', {'conversationId': conversationId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
