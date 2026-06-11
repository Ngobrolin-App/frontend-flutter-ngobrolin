import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/settings_repository.dart';
import '../base_view_model.dart';
import 'dart:developer' as developer;

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

  /// Fetches user profile data from the API
  Future<bool> fetchUserProfile(String userId) async {
    return await runBusyFuture(() async {
          try {
            final result = await _userRepository.getUserById(userId);
            _user = result.data;
            await _checkIfUserBlocked();
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

  /// Checks if the current user is blocked
  Future<void> _checkIfUserBlocked() async {
    if (_user == null) return;
    try {
      _isBlocked = await _settingsRepository.isUserBlocked(_user!.id);
      notifyListeners();
    } catch (e) {
      developer.log(
        'UserProfileViewModel - _checkIfUserBlocked() error: $e',
        name: 'UserProfileViewModel',
      );
      setError(e.toString());
    }
  }

  /// Blocks the current user
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

  /// Unblocks the current user
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

  /// Toggles block status of the user
  Future<bool> toggleBlockUser() async {
    if (_isBlocked) {
      return await unblockUser();
    } else {
      return await blockUser();
    }
  }
}
