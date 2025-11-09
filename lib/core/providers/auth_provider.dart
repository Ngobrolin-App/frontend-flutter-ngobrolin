import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? get token => _token;

  bool _authenticated = false;
  bool get authenticated => _authenticated;

  final AuthRepository _repo = AuthRepository();

  Future<void> init() async {
    try {
      final token = await _repo.getToken();
      _token = token;
      _authenticated = token != null && token.isNotEmpty;
    } catch (_) {
      _token = null;
      _authenticated = false;
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    // TODO: call API via Dio, receive token
    _token = 'mock-token';
    _authenticated = true;
    notifyListeners();
  }

  Future<void> signUp(String username, String password) async {
    final repo = AuthRepository();
    try {
      final token = await repo.getToken();
      if (token != null && token.isNotEmpty) {
        _token = token;
        _authenticated = true;
      } else {
        _authenticated = false;
      }
      notifyListeners();
    } catch (e) {
      _authenticated = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    // TODO: call API
  }

  void signOut() {
    _token = null;
    _authenticated = false;
    notifyListeners();
  }
}
