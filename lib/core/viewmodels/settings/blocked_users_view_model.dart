import '../../models/user.dart';
import '../../repositories/settings_repository.dart';
import '../base_view_model.dart';

class BlockedUsersViewModel extends BaseViewModel {
  final SettingsRepository _settingsRepository;

  List<Map<String, dynamic>> _blockedUsers = [];
  List<Map<String, dynamic>> get blockedUsers => _blockedUsers;

  BlockedUsersViewModel({SettingsRepository? settingsRepository})
      : _settingsRepository = settingsRepository ?? SettingsRepository();

  /// Fetches the list of blocked users
  Future<bool> fetchBlockedUsers() async {
    return await runBusyFuture(() async {
      try {
        final users = await _settingsRepository.getBlockedUsers();

        // Convert to map format for compatibility with existing UI
        _blockedUsers = users
            .map(
              (user) => {
                'id': user.id,
                'username': user.username,
                'name': user.name,
                'avatarUrl': user.avatarUrl,
              },
            )
            .toList();

        return true;
      } catch (e) {
        setError(e.toString());
        return false;
      }
    }) ?? false;
  }

  /// Fetches blocked users with dummy data for testing
  Future<bool> fetchBlockedUsersDummy() async {
    return await runBusyFuture(() async {
      try {
        // Mock User objects for blocked users
        final mockUsers = [
          User(
            id: '1',
            username: 'johndoe',
            name: 'John Doe',
            bio: null,
            avatarUrl: null,
            isPrivate: false,
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          User(
            id: '2',
            username: 'janesmith',
            name: 'Jane Smith',
            bio: null,
            avatarUrl: null,
            isPrivate: false,
            createdAt: DateTime.now().subtract(const Duration(days: 25)),
            updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          User(
            id: '3',
            username: 'mikejohnson',
            name: 'Mike Johnson',
            bio: null,
            avatarUrl: null,
            isPrivate: false,
            createdAt: DateTime.now().subtract(const Duration(days: 20)),
            updatedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ];

        // Convert to map format for compatibility with existing UI
        _blockedUsers = mockUsers
            .map(
              (user) => {
                'id': user.id,
                'username': user.username,
                'name': user.name,
                'avatarUrl': user.avatarUrl,
              },
            )
            .toList();

        return true;
      } catch (e) {
        setError(e.toString());
        return false;
      }
    }) ?? false;
  }

  /// Unblocks a user
  Future<bool> unblockUser(String userId) async {
    return await runBusyFuture(() async {
      try {
        final success = await _settingsRepository.unblockUser(userId);

        if (success) {
          // Remove from local list
          _blockedUsers.removeWhere((user) => user['id'] == userId);
        }

        return success;
      } catch (e) {
        setError(e.toString());
        return false;
      }
    }) ?? false;
  }

  /// Unblocks a user with dummy implementation
  Future<bool> unblockUserDummy(String userId) async {
    return await runBusyFuture(() async {
      try {
        // Simulate API call delay
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Remove from local list
        _blockedUsers.removeWhere((user) => user['id'] == userId);
        
        return true;
      } catch (e) {
        setError(e.toString());
        return false;
      }
    }) ?? false;
  }

  /// Checks if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      return await _settingsRepository.isUserBlocked(userId);
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }
}