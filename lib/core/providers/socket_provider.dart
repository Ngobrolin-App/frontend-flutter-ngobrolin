import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/socket_service.dart';

class SocketProvider extends ChangeNotifier {
  final SocketService _socket = SocketService();

  bool _connected = false;
  bool get connected => _connected;

  Future<void> init({String? token}) async {
    final baseUrl = dotenv.env['WS_BASE_URL'] ?? 'http://localhost:3000';
    print('SocketProvider.init: baseUrl=$baseUrl');

    String? authToken = token;
    if (authToken == null || authToken.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      authToken = prefs.getString('auth_token');
    }
    print('SocketProvider.init: token ${authToken != null && authToken.isNotEmpty ? 'present' : 'null'}');

    // Putuskan koneksi lama sebelum membuat yang baru
    if (_socket.isConnected) {
      print('SocketProvider.init: disconnecting previous socket');
      _socket.disconnect();
    }

    _socket.connect(url: baseUrl, token: authToken);

    _socket.on('connect', (_) {
      print('SocketProvider: connected');
      _connected = true;

      if (authToken != null && authToken.isNotEmpty) {
        _socket.emit('authenticate', {'token': authToken});
      }

      notifyListeners();
    });

    _socket.on('disconnect', (_) {
      print('SocketProvider: disconnected');
      _connected = false;
      notifyListeners();
    });

    // Contoh event pesan
    _socket.on('message', (data) {
      print('SocketProvider: Incoming message: $data');
      // handle incoming message
      notifyListeners();
    });
  }

  void on(String event, void Function(dynamic data) handler) {
    _socket.on(event, handler);
  }

  // Tambah off untuk melepas listener dari luar
  void off(String event) {
    _socket.off(event);
  }

  // Join conversation room passthrough
  void joinConversation(String conversationId) {
    _socket.joinConversation(conversationId);
  }

  // Leave conversation room passthrough
  void leaveConversation(String conversationId) {
    _socket.leaveConversation(conversationId);
  }

  // Emit typing start event
  void sendTypingStart(String conversationId) {
    _socket.emit('typing_start', {'conversationId': conversationId});
  }

  // Emit typing stop event
  void sendTypingStop(String conversationId) {
    _socket.emit('typing_stop', {'conversationId': conversationId});
  }

  // Emit user status update
  void updateStatus(String status) {
    _socket.emit('update_status', {'status': status});
  }

  void disposeSocket() {
    _socket.disconnect();
  }
}
