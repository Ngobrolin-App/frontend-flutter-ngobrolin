import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../base_view_model.dart';

class ProfileViewModel extends BaseViewModel {
  final UserRepository _userRepository;

  UserModel? _user;
  UserModel? get user => _user;

  ProfileViewModel({UserRepository? userRepository})
    : _userRepository = userRepository ?? UserRepository();

  /// Initializes the profile view model with user data
  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  /// Fetches user profile data from the API
  Future<bool> fetchCurrentProfile() async {
    return await runBusyFuture(() async {
          try {
            final response = await _userRepository.getCurrentProfile();
            _user = response.data;
            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

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
            // Update profile information
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

              final updatedUser = result.data;
              _user = updatedUser;

              setSuccess(result.message);

              success = result.isSuccess;
            }

            // Update profile picture if provided (via updateProfile param which seems redundant with updateProfilePicture method, keeping for backward compat)
            if (avatarUrl != null) {
              // Assuming avatarUrl passed here is a path to upload, or a URL?
              // If it's a URL, we just update user?
              // The original code called uploadProfilePicture with this.
              // Let's assume it's a file path for upload.
              final result = await _userRepository.uploadProfilePicture(
                _user!.id,
                avatarUrl,
              );
              final updatedUser = result.data;
              final newAvatarUrl = updatedUser?.avatarUrl;
              if (newAvatarUrl != null) {
                _user = _user!.copyWith(avatarUrl: newAvatarUrl);
              }
              setSuccess(result.message);

              success = result.isSuccess;
            }

            notifyListeners();
            return success;
          } catch (e) {
            print('ProfileViewModel - updateProfile() error: $e');
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }
}
