import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/socket_service.dart';

class SocketProvider extends ChangeNotifier {
  final SocketService _socket = SocketService();

  bool _connected = false;
  bool get connected => _connected;

  void init({String? token}) {
    final baseUrl = dotenv.env['WS_BASE_URL'] ?? 'http://localhost:3000';
    print('baseUrl: $baseUrl');

    // Ambil token dari SharedPreferences jika tidak diberikan
    String? authToken = token;
    SharedPreferences.getInstance().then((prefs) {
      authToken ??= prefs.getString('auth_token');
    });

    _socket.connect(url: baseUrl, token: authToken);

    _socket.on('connect', (_) {
      _connected = true;

      // Emit authenticate agar backend mengenali userId untuk room & sender_id
      if (authToken != null && authToken!.isNotEmpty) {
        _socket.emit('authenticate', {'token': authToken});
      }

      notifyListeners();
    });

    _socket.on('disconnect', (_) {
      _connected = false;
      notifyListeners();
    });

    // Example chat event bindings
    _socket.on('message', (data) {
      // handle incoming message
      if (kDebugMode) {
        print('Incoming message: $data');
      }
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

  // Emit via socket if you want to send realtime messages (optional)
  void sendMessage({required String conversationId, required String content, String type = 'text'}) {
    _socket.emit('send_message', {
      'conversationId': conversationId,
      'content': content,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void disposeSocket() {
    _socket.disconnect();
  }
}
