import '../../models/user.dart';
import '../../repositories/auth_repository.dart';
import '../base_view_model.dart';

class AuthViewModel extends BaseViewModel {
  final AuthRepository _authRepository;

  String? _token;
  String? get token => _token;

  bool _authenticated = false;
  bool get authenticated => _authenticated;

  User? _user;
  User? get user => _user;

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

  /// Signs in a user with username and password
  Future<bool> signIn(String username, String password) async {
    return await runBusyFuture(() async {
          try {
            final authResponse = await _authRepository.signIn(username, password);
            _token = authResponse.token;
            _user = authResponse.user;
            _authenticated = true;
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
    required String name,
    required String password,
  }) async {
    return await runBusyFuture(() async {
          try {
            final authResponse = await _authRepository.signUp(
              username: username,
              name: name,
              password: password,
            );
            _token = authResponse.token;
            _user = authResponse.user;
            _authenticated = true;
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

  /// Signs out the current user
  void signOut() {
    runBusyFuture(() async {
      try {
        await _authRepository.signOut();
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
}
