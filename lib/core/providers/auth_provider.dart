import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? get token => _token;

  bool _authenticated = false;
  bool get authenticated => _authenticated;

  Future<void> signIn(String email, String password) async {
    // TODO: call API via Dio, receive token
    _token = 'mock-token';
    _authenticated = true;
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
    // TODO: call API
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
