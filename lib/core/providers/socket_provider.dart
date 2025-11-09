import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/socket_service.dart';

class SocketProvider extends ChangeNotifier {
  final SocketService _socket = SocketService();

  bool _connected = false;
  bool get connected => _connected;

  void init({String? token}) {
    final baseUrl = dotenv.env['WS_BASE_URL'] ?? 'ws://localhost:3000';
    print('baseUrl: $baseUrl');
    _socket.connect(url: baseUrl, token: token);

    _socket.on('connect', (_) {
      _connected = true;
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

  void sendMessage({required String toUserId, required String content}) {
    _socket.emit('message', {
      'to': toUserId,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void disposeSocket() {
    _socket.disconnect();
  }
}
