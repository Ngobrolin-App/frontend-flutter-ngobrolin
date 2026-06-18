import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../base_view_model.dart';
import 'dart:developer' as developer;

/// ViewModel responsible for retrieving and updating user profile data,
/// including textual records and avatar media uploads.
class ProfileViewModel extends BaseViewModel {
  final UserRepository _userRepository;

  UserModel? _user;
  UserModel? get user => _user;

  ProfileViewModel({UserRepository? userRepository})
    : _userRepository = userRepository ?? UserRepository();

  /// Statically updates the local user model reference instance from external components.
  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  /// Fetches the latest authenticated user profile metrics from the network API.
  Future<bool> fetchCurrentProfile() async {
    developer.log(
      'ProfileViewModel - fetchCurrentProfile',
      name: 'ProfileViewModel',
    );
    return await runBusyFuture(() async {
          try {
            final response = await _userRepository.getCurrentProfile();
            _user = response.data;
            notifyListeners();
            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Updates profile information text values and/or triggers binary avatar media uploads sequentially.
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? bio,
    String? avatarUrl,
    String? newPassword,
    String? currentPassword,
  }) async {
    if (_user == null) return false;

    return await runBusyFuture(() async {
          try {
            var success = true;

            // Section A: Evaluates and updates textual parameters or password credentials
            if (name != null ||
                bio != null ||
                email != null ||
                currentPassword != null ||
                newPassword != null) {
              final result = await _userRepository.updateProfile(
                userId: _user!.id,
                name: name,
                email: email,
                bio: bio,
                currentPassword: currentPassword,
                newPassword: newPassword,
              );

              _user = result.data;
              success = result.isSuccess;
              setSuccess(result.message);
            }

            // Section B: Processes direct profile image upload transactions if a valid file path is passed
            if (avatarUrl != null) {
              final result = await _userRepository.uploadProfilePicture(
                _user!.id,
                avatarUrl,
              );

              final updatedUser = result.data;
              final newAvatarUrl = updatedUser?.avatarUrl;

              if (newAvatarUrl != null && _user != null) {
                _user = _user!.copyWith(avatarUrl: newAvatarUrl);
              } else if (updatedUser != null) {
                _user = updatedUser;
              }

              success = result.isSuccess;
              setSuccess(result.message);
            }

            notifyListeners();
            return success;
          } catch (e) {
            developer.log(
              "ProfileViewModel - updateProfile() error $e",
              name: 'ProfileViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }
}
