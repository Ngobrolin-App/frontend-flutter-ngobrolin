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

  String? _token;
  String? get token => _token;

  bool _authenticated = false;
  bool get authenticated => _authenticated;

  UserModel? _user;
  UserModel? get user => _user;

  AuthViewModel({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository() {
    checkAuthStatus();
  }

  /// Checks the local authentication persistency status during startup.
  Future<void> checkAuthStatus() async {
    setLoading(true);
    try {
      _authenticated = await _authRepository.isAuthenticated();
      if (_authenticated) {
        _token = await _authRepository.getToken();
        _user = await _authRepository.getCurrentUser();
      }
      notifyListeners();
    } catch (e) {
      developer.log(
        'AuthViewModel - checkAuthStatus() error: $e',
        name: 'AuthViewModel',
      );
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  /// Handles user sign-in requests using email/username and password.
  Future<bool> signIn(String usernameOrEmail, String password) async {
    return await runBusyFuture(() async {
          try {
            final response = await _authRepository.login(
              usernameOrEmail,
              password,
            );
            final authResponse = response.data;

            if (authResponse == null) {
              setError('invalid_response');
              return false;
            }

            setSuccess(response.message);

            _token = authResponse.token;
            _user = authResponse.user;
            _authenticated = true;

            // Execute FCM registration in the background without mutating global error state
            await _executeFcmRegistration();

            notifyListeners();
            return response.isSuccess;
          } catch (e) {
            developer.log(
              'AuthViewModel - signIn() error: $e',
              name: 'AuthViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Registers a new user account and authenticates immediately upon success.
  Future<bool> signUp({
    required String username,
    required String email,
    required String name,
    required String password,
  }) async {
    return await runBusyFuture(() async {
          try {
            final response = await _authRepository.register(
              username: username,
              email: email,
              name: name,
              password: password,
            );

            final authResponse = response.data;
            if (authResponse == null) {
              setError('invalid_response');
              return false;
            }

            setSuccess(response.message);

            _token = authResponse.token;
            _user = authResponse.user;
            _authenticated = true;

            await _executeFcmRegistration();

            notifyListeners();
            return response.isSuccess;
          } catch (e) {
            developer.log(
              'AuthViewModel - signUp() error: $e',
              name: 'AuthViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Triggers a password recovery link to the specified email address.
  Future<bool> forgotPassword(String email) async {
    return await runBusyFuture(() async {
          try {
            final result = await _authRepository.forgotPassword(email);
            setSuccess(result.message);
            return result.isSuccess;
          } catch (e) {
            developer.log(
              'AuthViewModel - forgotPassword() error: $e',
              name: 'AuthViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Resets the user's password using a verification token.
  Future<bool> resetPassword(String token, String newPassword) async {
    return await runBusyFuture(() async {
          try {
            final result = await _authRepository.resetPassword(
              token,
              newPassword,
            );
            setSuccess(result.message);
            return result.isSuccess;
          } catch (e) {
            developer.log(
              'AuthViewModel - resetPassword() error: $e',
              name: 'AuthViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Performs a clean sign-out by unlinking the FCM token and clearing local session states.
  Future<bool> signOut() async {
    return await runBusyFuture(() async {
          try {
            try {
              final fcmToken = await FirebaseMessaging.instance.getToken();
              if (fcmToken != null && fcmToken.isNotEmpty) {
                await serviceLocator<UserRepository>().deleteFcmToken(fcmToken);
              }
            } catch (fcmError) {
              developer.log(
                'AuthViewModel - Failed to delete FCM token on server: $fcmError',
              );
            }

            await _authRepository.signOut();

            _token = null;
            _authenticated = false;
            _user = null;
            notifyListeners();

            return true;
          } catch (e) {
            developer.log(
              'AuthViewModel - signOut() error: $e',
              name: 'AuthViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Manually triggers FCM registration with UI loading state indications.
  Future<bool> registerFcmToken() async {
    return await runBusyFuture(() async {
          final isSuccess = await _executeFcmRegistration();
          if (!isSuccess) {
            setError('fcm_registration_failed');
          }
          return isSuccess;
        }) ??
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
    } catch (e) {
      developer.log(
        'AuthViewModel - _executeFcmRegistration() error: $e',
        name: 'AuthViewModel',
      );
      // Returns false cleanly without triggering setError to keep primary Auth UI stream uninterrupted
      return false;
    }
  }
}
