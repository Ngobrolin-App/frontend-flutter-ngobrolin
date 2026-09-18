import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// JWT storage in encrypted storage (keystore/Keychain).
/// Migrates a legacy plaintext token from SharedPreferences on first read.
class TokenStorage {
  static const String _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> delete() => _storage.delete(key: _tokenKey);

  Future<String?> read() async {
    String? token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) {
      try {
        // One-time migration from legacy plaintext SharedPreferences storage
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString(_tokenKey);
        if (token != null && token.isNotEmpty) {
          await _storage.write(key: _tokenKey, value: token);
          await prefs.remove(_tokenKey);
          developer.log(
            'TokenStorage: migrated legacy token to secure storage',
            name: 'TokenStorage',
          );
        }
      } catch (e) {
        developer.log('TokenStorage: migration failed: $e', name: 'TokenStorage');
      }
    }
    return token;
  }
}
