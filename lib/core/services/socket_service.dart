import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect({required String url, String? token}) {
    print('SocketService: connecting to $url with token: ${token != null ? 'present' : 'null'}');
    final opts = IO.OptionBuilder()
        .setTransports(['websocket'])
        .setPath('/socket.io')
        .enableAutoConnect()
        .setTimeout(10000)
        .setExtraHeaders(token != null ? {'Authorization': 'Bearer $token'} : {})
        .build();

    _socket = IO.io(url, opts);

    _socket?.on('connecting', (_) => print('Socket connecting...'));
    _socket?.on('connect', (_) => print('Socket connected'));
    _socket?.on('connect_error', (err) => print('Socket connect_error: $err'));
    _socket?.on('error', (err) => print('Socket error: $err'));
    _socket?.on('disconnect', (_) => print('Socket disconnect'));
    _socket?.on('reconnect', (attempt) => print('Socket reconnect: $attempt'));
    _socket?.on('reconnect_attempt', (attempt) => print('Socket reconnect_attempt: $attempt'));
    _socket?.on('reconnect_failed', (_) => print('Socket reconnect_failed'));
  }

  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  // Lepas listener event tertentu
  void off(String event, [dynamic handler]) {
    _socket?.off(event, handler);
  }

  // Join/leave conversation rooms
  void joinConversation(String conversationId) {
    _socket?.emit('join_conversation', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('leave_conversation', {'conversationId': conversationId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
