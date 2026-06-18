import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/settings_repository.dart';
import '../base_view_model.dart';
import 'dart:developer' as developer;

/// ViewModel responsible for inspecting external peer profiles and managing targeting features
/// like blocking or unblocking corresponding users.
class UserProfileViewModel extends BaseViewModel {
  final UserRepository _userRepository;
  final SettingsRepository _settingsRepository;

  UserModel? _user;
  UserModel? get user => _user;

  bool _isBlocked = false;
  bool get isBlocked => _isBlocked;

  UserProfileViewModel({
    UserRepository? userRepository,
    SettingsRepository? settingsRepository,
  }) : _userRepository = userRepository ?? UserRepository(),
       _settingsRepository = settingsRepository ?? SettingsRepository();

  /// Fetches standard user profile metrics and evaluates target relationship blocks.
  Future<bool> fetchUserProfile(String userId) async {
    return await runBusyFuture(() async {
          try {
            final result = await _userRepository.getUserById(userId);
            _user = result.data;

            // Evaluates relationship constraints quietly prior to refreshing components layout
            await _checkIfUserBlocked();

            notifyListeners();
            return true;
          } catch (e) {
            developer.log(
              'UserProfileViewModel - fetchUserProfile() error: $e',
              name: 'UserProfileViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Internal checker routine targeting remote database blacklists.
  /// Removes duplicate UI notifications to stay lightweight.
  Future<void> _checkIfUserBlocked() async {
    if (_user == null) return;
    try {
      _isBlocked = await _settingsRepository.isUserBlocked(_user!.id);
    } catch (e) {
      developer.log(
        'UserProfileViewModel - _checkIfUserBlocked() error: $e',
        name: 'UserProfileViewModel',
      );
      // Suppresses global state errors to prevent valid profiles layout from breaking unexpectedly
    }
  }

  /// Registers a block flag against the focused user account index.
  Future<bool> blockUser() async {
    if (_user == null) return false;
    return await runBusyFuture(() async {
          try {
            final result = await _settingsRepository.blockUser(_user!.id);
            final success = result.isSuccess;

            if (success) {
              setSuccess(result.message);
              _isBlocked = true;
            }

            notifyListeners();
            return success;
          } catch (e) {
            developer.log(
              'UserProfileViewModel - blockUser() error: $e',
              name: 'UserProfileViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Removes a block flag constraint targeting the focused user account instance.
  Future<bool> unblockUser() async {
    if (_user == null) return false;
    return await runBusyFuture(() async {
          try {
            final result = await _settingsRepository.unblockUser(_user!.id);
            final success = result.isSuccess;

            if (success) {
              setSuccess(result.message);
              _isBlocked = false;
            }

            notifyListeners();
            return success;
          } catch (e) {
            developer.log(
              'UserProfileViewModel - unblockUser() error: $e',
              name: 'UserProfileViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Proxy wrapper switch mapping to toggle user structural blockage boundaries seamlessly.
  Future<bool> toggleBlockUser() async {
    if (_isBlocked) {
      return await unblockUser();
    } else {
      return await blockUser();
    }
  }
}
