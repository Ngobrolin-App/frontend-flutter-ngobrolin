import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../base_view_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../di/service_locator.dart';
import '../../repositories/user_repository.dart';
import 'dart:developer' as developer;

/// ViewModel responsible for managing authentication states and device token registrations.
class AuthViewModel extends BaseViewModel {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  static const String _logName = 'AuthViewModel';

  String? _token;
  String? get token => _token;

  bool _authenticated = false;
  bool get authenticated => _authenticated;

  UserModel? _user;
  UserModel? get user => _user;

  String? get currentUserId => _user?.id;

  AuthViewModel({
    AuthRepository? authRepository,
    UserRepository? userRepository,
  }) : _authRepository = authRepository ?? AuthRepository(),
       _userRepository = userRepository ?? UserRepository() {
    checkAuthStatus();
  }

  /// Checks the local authentication persistency status during startup.
  Future<bool> checkAuthStatus() async {
    final result = await runBusyFuture(
      () async {
        final hasToken = await _authRepository.isAuthenticated();

        if (!hasToken) return false;

        _token = await _authRepository.getToken();
        final result = await _userRepository.getCurrentProfile();

        if (result.isSuccess && result.data != null) {
          _authenticated = true;
          _user = result.data;
          notifyListeners();
          return true;
        }

        return false;
      },
      logName: _logName,
      logContext: 'checkAuthStatus()',
    );

    // Ensures cleanup state runs cleanly if token is invalid or getProfile fails
    if (result == null || result == false) {
      _authenticated = false;
      _token = null;
      _user = null;
      notifyListeners();
      return false;
    }

    return true;
  }

  /// Handles user sign-in requests using email/username and password.
  Future<bool> signIn(String usernameOrEmail, String password) async {
    return await runBusyFuture(
          () async {
            final response = await _authRepository.login(
              usernameOrEmail,
              password,
            );
            final authResponse = response.data;

            if (authResponse == null) {
              // Throw to be caught by BaseViewModel logger
              throw Exception('invalid_response');
            }

            setSuccess(response.message);

            _token = authResponse.token;
            _user = authResponse.user;
            _authenticated = true;

            // Execute FCM registration in the background without mutating global error state
            await _executeFcmRegistration();

            notifyListeners();
            return response.isSuccess;
          },
          logName: _logName,
          logContext: 'signIn()',
        ) ??
        false;
  }

  /// Registers a new user account and authenticates immediately upon success.
  Future<bool> signUp({
    required String username,
    required String email,
    required String name,
    required String password,
  }) async {
    return await runBusyFuture(
          () async {
            final response = await _authRepository.register(
              username: username,
              email: email,
              name: name,
              password: password,
            );

            final authResponse = response.data;
            if (authResponse == null) {
              throw Exception('invalid_response');
            }

            setSuccess(response.message);

            _token = authResponse.token;
            _user = authResponse.user;
            _authenticated = true;

            await _executeFcmRegistration();

            notifyListeners();
            return response.isSuccess;
          },
          logName: _logName,
          logContext: 'signUp()',
        ) ??
        false;
  }

  /// Triggers a password recovery link to the specified email address.
  Future<bool> forgotPassword(String email) async {
    return await runBusyFuture(
          () async {
            final result = await _authRepository.forgotPassword(email);
            setSuccess(result.message);
            return result.isSuccess;
          },
          logName: _logName,
          logContext: 'forgotPassword()',
        ) ??
        false;
  }

  /// Resets the user's password using a verification token.
  Future<bool> resetPassword(String token, String newPassword) async {
    return await runBusyFuture(
          () async {
            final result = await _authRepository.resetPassword(
              token,
              newPassword,
            );
            setSuccess(result.message);
            return result.isSuccess;
          },
          logName: _logName,
          logContext: 'resetPassword()',
        ) ??
        false;
  }

  /// Performs a clean sign-out by unlinking the FCM token and clearing local session states.
  Future<bool> signOut() async {
    return await runBusyFuture(
          () async {
            try {
              final fcmToken = await FirebaseMessaging.instance.getToken();
              if (fcmToken != null && fcmToken.isNotEmpty) {
                await serviceLocator<UserRepository>().deleteFcmToken(fcmToken);
              }
            } catch (e, stackTrace) {
              // Inner catch is intentionally left out to not stop the Sign Out flow
              developer.log(
                'Failed to delete FCM token on server: $e',
                name: _logName,
                error: e,
                stackTrace: stackTrace,
              );
            }

            await _authRepository.signOut();

            _token = null;
            _authenticated = false;
            _user = null;
            notifyListeners();

            return true;
          },
          logName: _logName,
          logContext: 'signOut()',
        ) ??
        false;
  }

  /// Manually triggers FCM registration with UI loading state indications.
  Future<bool> registerFcmToken() async {
    return await runBusyFuture(
          () async {
            final isSuccess = await _executeFcmRegistration();
            if (!isSuccess) {
              throw Exception('fcm_registration_failed');
            }
            return isSuccess;
          },
          logName: _logName,
          logContext: 'registerFcmToken()',
        ) ??
        false;
  }

  /// Pure internal helper function to link device tokens to the backend server.
  /// This prevents background integration side-effects from throwing false positives to the UI.
  Future<bool> _executeFcmRegistration() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await serviceLocator<UserRepository>().registerFcmToken(fcmToken);
      }
      return true;
    } catch (e, stackTrace) {
      developer.log(
        '_executeFcmRegistration() error: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Returns false cleanly without triggering setError to keep primary Auth UI stream uninterrupted
      return false;
    }
  }
}
