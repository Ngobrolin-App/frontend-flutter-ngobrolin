import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:developer' as developer;

class SocketService {
  IO.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect({required String url, String? token}) {
    developer.log('SocketService: connecting to $url', name: 'SocketService');

    // Konfigurasi opsi socket
    final opts = IO.OptionBuilder()
        .setTransports(['websocket'])
        .setPath('/socket.io')
        .enableAutoConnect()
        .setTimeout(10000)
        // Menggunakan setExtraHeaders sangat bagus untuk autentikasi awal (handshake)
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
  }

  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void off(String event, [dynamic handler]) {
    _socket?.off(event, handler);
  }

  // Bersihkan semua core event listener untuk mencegah duplikasi/kebocoran
  void clearListeners() {
    _socket?.clearListeners();
  }

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
