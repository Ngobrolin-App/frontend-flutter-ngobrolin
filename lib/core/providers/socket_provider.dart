import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/socket_service.dart';
import 'dart:developer' as developer;

class SocketProvider extends ChangeNotifier {
  final SocketService _socket = SocketService();

  bool _connected = false;
  bool get connected => _connected;

  bool _authenticated = false;
  bool get authenticated => _authenticated;

  Future<void> init({String? token}) async {
    final baseUrl = dotenv.env['WS_BASE_URL'] ?? 'http://localhost:3000';

    String? authToken = token;
    if (authToken == null || authToken.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      authToken = prefs.getString('auth_token');
    }

    // SOLUSI: Bersihkan koneksi lama dan pendengar event lama secara menyeluruh
    _resetState();
    _socket.clearListeners();
    _socket.disconnect();

    developer.log(
      'SocketProvider.init: Initializing new socket connection',
      name: 'SocketProvider',
    );
    _socket.connect(url: baseUrl, token: authToken);

    // Set up core listeners
    _setupSocketListeners(authToken);
  }

  void _setupSocketListeners(String? authToken) {
    _socket.on('connect', (_) {
      developer.log('SocketProvider: connected', name: 'SocketProvider');
      _connected = true;

      // Gunakan fallback emit ini HANYA JIKA backend tidak membaca extraHeaders saat handshake
      if (authToken != null && authToken.isNotEmpty) {
        _socket.emit('authenticate', {'token': authToken});
      }

      notifyListeners();
    });

    _socket.on('disconnect', (_) {
      developer.log('SocketProvider: disconnected', name: 'SocketProvider');
      _connected = false;
      _authenticated = false; // SOLUSI: Reset status auth saat koneksi terputus

      notifyListeners();
    });

    _socket.on('authenticated', (data) {
      developer.log(
        'SocketProvider: authenticated successfully',
        name: 'SocketProvider',
      );
      _authenticated = true;
      notifyListeners();
    });

    _socket.on('auth_error', (data) {
      developer.log(
        'SocketProvider: auth_error - $data',
        name: 'SocketProvider',
      );
      _connected = false;
      _authenticated = false;
      notifyListeners();
    });
  }

  void _resetState() {
    _connected = false;
    _authenticated = false;
  }

  // Passthrough methods untuk UI / Screen Components
  void on(String event, void Function(dynamic data) handler) {
    _socket.on(event, handler);
  }

  void off(String event, [dynamic handler]) {
    _socket.off(event, handler);
  }

  void joinConversation(String conversationId) {
    _socket.joinConversation(conversationId);
  }

  void leaveConversation(String conversationId) {
    _socket.leaveConversation(conversationId);
  }

  void sendTypingStart(String conversationId) {
    _socket.emit('typing_start', {'conversationId': conversationId});
  }

  void sendTypingStop(String conversationId) {
    _socket.emit('typing_stop', {'conversationId': conversationId});
  }

  void updateStatus(String status) {
    _socket.emit('update_status', {'status': status});
  }

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }
}
