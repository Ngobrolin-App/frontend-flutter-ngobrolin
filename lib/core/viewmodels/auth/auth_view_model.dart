import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../base_view_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../di/service_locator.dart';
import '../../repositories/user_repository.dart';

class AuthViewModel extends BaseViewModel {
  final AuthRepository _authRepository;

  String? _token;
  String? get token => _token;

  bool _authenticated = false;
  bool get authenticated => _authenticated;

  UserModel? _user;
  UserModel? get user => _user;

  AuthViewModel({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository() {
    _checkAuthStatus();
  }

  /// Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    setLoading(true);
    try {
      _authenticated = await _authRepository.isAuthenticated();
      if (_authenticated) {
        _token = await _authRepository.getToken();
        _user = await _authRepository.getCurrentUser();
      }
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  /// Signs in a user with username or email and password
  Future<bool> signIn(String usernameOrEmail, String password) async {
    return await runBusyFuture(() async {
          try {
            final authResponse = await _authRepository.signIn(usernameOrEmail, password);
            _token = authResponse.token;
            _user = authResponse.user;
            _authenticated = true;
            await _registerFcmToken();
            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Registers a new user
  Future<bool> signUp({
    required String username,
    required String email,
    required String name,
    required String password,
  }) async {
    return await runBusyFuture(() async {
          try {
            final authResponse = await _authRepository.signUp(
              username: username,
              email: email,
              name: name,
              password: password,
            );
            _token = authResponse.token;
            _user = authResponse.user;
            _authenticated = true;
            await _registerFcmToken();
            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Sends a password reset request
  Future<bool> forgotPassword(String email) async {
    return await runBusyFuture(() async {
          try {
            return await _authRepository.forgotPassword(email);
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Resets password using token
  Future<bool> resetPassword(String token, String newPassword) async {
    return await runBusyFuture(() async {
          try {
            return await _authRepository.resetPassword(token, newPassword);
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Signs out the current user
  void signOut() {
    runBusyFuture(() async {
      try {
        await _authRepository.signOut();
        try {
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null && fcmToken.isNotEmpty) {
            await serviceLocator<UserRepository>().deleteFcmToken(fcmToken);
          }
        } catch (_) {}
        _token = null;
        _authenticated = false;
        _user = null;
        return true;
      } catch (e) {
        setError(e.toString());
        return false;
      }
    });
  }

  Future<void> _registerFcmToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      await serviceLocator<UserRepository>().registerFcmToken(fcmToken);
    }
  }
}
