import '../../models/user.dart';
import '../../repositories/user_repository.dart';
import '../base_view_model.dart';

class ProfileViewModel extends BaseViewModel {
  final UserRepository _userRepository;
  
  // User profile data
  Map<String, dynamic> _userData = {
    'id': '',
    'name': '',
    'username': '',
    'bio': '',
    'avatarUrl': null,
  };

  Map<String, dynamic> get userData => _userData;

  ProfileViewModel({UserRepository? userRepository}) 
      : _userRepository = userRepository ?? UserRepository();

  /// Initializes the profile view model with user data
  void initWithUserData(Map<String, dynamic> userData) {
    _userData = userData;
    notifyListeners();
  }

  /// Fetches user profile data from the API
  Future<bool> fetchUserProfile(String userId) async {
    return await runBusyFuture(() async {
      try {
        final user = await _userRepository.getUserById(userId);
        
        // Convert to map format for compatibility with existing UI
        _userData = {
          'id': user.id,
          'name': user.name,
          'username': user.username,
          'bio': user.bio ?? '',
          'avatarUrl': user.avatarUrl,
          'isPrivate': user.isPrivate,
        };
        
        return true;
      } catch (e) {
        setError(e.toString());
        return false;
      }
    }) ?? false;
  }

  /// Updates user profile information
  Future<bool> updateProfile({
    String? name,
    String? bio,
    String? avatarUrl,
    String? newPassword,
    String? currentPassword,
  }) async {
    return await runBusyFuture(() async {
      try {
        // Update profile information
        if (name != null || bio != null) {
          final user = await _userRepository.updateProfile(
            userId: _userData['id'],
            name: name,
            bio: bio,
          );
          
          // Update local data
          _userData['name'] = user.name;
          _userData['bio'] = user.bio ?? '';
        }
        
        // Update password if provided
        if (newPassword != null && currentPassword != null) {
          await _userRepository.updatePassword(
            userId: _userData['id'],
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
        }
        
        // Update profile picture if provided
        if (avatarUrl != null) {
          final newAvatarUrl = await _userRepository.uploadProfilePicture(
            _userData['id'],
            avatarUrl,
          );
          _userData['avatarUrl'] = newAvatarUrl;
        }
        
        return true;
      } catch (e) {
        setError(e.toString());
        return false;
      }
    }) ?? false;
  }

  /// Updates user profile picture
  Future<bool> updateProfilePicture(String imagePath) async {
    return await runBusyFuture(() async {
      try {
        final avatarUrl = await _userRepository.uploadProfilePicture(
          _userData['id'],
          imagePath,
        );
        
        // Update local data
        _userData['avatarUrl'] = avatarUrl;
        
        return true;
      } catch (e) {
        setError(e.toString());
        return false;
      }
    }) ?? false;
  }
}