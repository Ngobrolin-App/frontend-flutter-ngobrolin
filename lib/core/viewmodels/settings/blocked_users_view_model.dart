import '../../models/user.dart';
import '../../repositories/settings_repository.dart';
import '../base_view_model.dart';

class BlockedUsersViewModel extends BaseViewModel {
  final SettingsRepository _settingsRepository;

  List<Map<String, dynamic>> _blockedUsers = [];
  List<Map<String, dynamic>> get blockedUsers => _blockedUsers;

  // Pagination state
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  BlockedUsersViewModel({SettingsRepository? settingsRepository})
    : _settingsRepository = settingsRepository ?? SettingsRepository();

  /// Fetches the list of blocked users (first page)
  Future<bool> fetchBlockedUsers() async {
    return await runBusyFuture(() async {
          try {
            _page = 1;
            _hasMore = true;
            final users = await _settingsRepository.getBlockedUsers(page: _page, limit: _limit);

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

            _hasMore = users.length == _limit;
            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Loads next page of blocked users and appends
  Future<void> loadMoreBlockedUsers() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      _page += 1;
      final users = await _settingsRepository.getBlockedUsers(page: _page, limit: _limit);

      final mapped = users
          .map(
            (user) => {
              'id': user.id,
              'username': user.username,
              'name': user.name,
              'avatarUrl': user.avatarUrl,
            },
          )
          .toList();

      _blockedUsers.addAll(mapped);
      _hasMore = users.length == _limit;
    } catch (e) {
      setError(e.toString());
      _page = (_page > 1) ? _page - 1 : 1;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Unblocks a user
  Future<bool> unblockUser(String userId) async {
    return await runBusyFuture(() async {
          try {
            final success = await _settingsRepository.unblockUser(userId);
            if (success) {
              _blockedUsers.removeWhere((user) => user['id'] == userId);
            }
            return success;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
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
        }) ??
        false;
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
