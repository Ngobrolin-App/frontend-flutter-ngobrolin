import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect({required String url, String? token}) {
    final opts = IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setTimeout(10000)
        .setExtraHeaders(token != null ? {'Authorization': 'Bearer $token'} : {})
        .build();

    _socket = IO.io(url, opts);
  }

  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  // Lepas listener event tertentu
  void off(String event) {
    _socket?.off(event);
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
