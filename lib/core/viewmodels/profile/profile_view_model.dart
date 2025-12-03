import '../../models/user.dart';
import '../../repositories/user_repository.dart';
import '../base_view_model.dart';

class ProfileViewModel extends BaseViewModel {
  final UserRepository _userRepository;

  User? _user;
  User? get user => _user;

  ProfileViewModel({UserRepository? userRepository})
    : _userRepository = userRepository ?? UserRepository();

  /// Initializes the profile view model with user data
  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  /// Fetches user profile data from the API
  Future<bool> fetchCurrentProfile() async {
    return await runBusyFuture(() async {
          try {
            _user = await _userRepository.getCurrentProfile();
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
    String? bio,
    String? avatarUrl,
    String? newPassword,
    String? currentPassword,
  }) async {
    if (_user == null) return false;

    return await runBusyFuture(() async {
          try {
            // Update profile information
            if (name != null || bio != null) {
              final updatedUser = await _userRepository.updateProfile(
                userId: _user!.id,
                name: name,
                bio: bio,
              );

              _user = updatedUser;
            }

            // Update password if provided
            if (newPassword != null && currentPassword != null) {
              await _userRepository.updatePassword(
                userId: _user!.id,
                currentPassword: currentPassword,
                newPassword: newPassword,
              );
            }

            // Update profile picture if provided (via updateProfile param which seems redundant with updateProfilePicture method, keeping for backward compat)
            if (avatarUrl != null) {
              // Assuming avatarUrl passed here is a path to upload, or a URL?
              // If it's a URL, we just update user?
              // The original code called uploadProfilePicture with this.
              // Let's assume it's a file path for upload.
              final newAvatarUrl = await _userRepository.uploadProfilePicture(_user!.id, avatarUrl);
              _user = _user!.copyWith(avatarUrl: newAvatarUrl);
            }

            notifyListeners();
            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Updates user profile picture
  Future<bool> updateProfilePicture(String imagePath) async {
    if (_user == null) return false;

    return await runBusyFuture(() async {
          try {
            final avatarUrl = await _userRepository.uploadProfilePicture(_user!.id, imagePath);

            _user = _user!.copyWith(avatarUrl: avatarUrl);
            notifyListeners();
            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }
}
