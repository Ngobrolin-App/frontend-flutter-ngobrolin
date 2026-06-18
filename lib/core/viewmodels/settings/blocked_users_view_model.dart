import '../../models/user_model.dart';
import '../../repositories/settings_repository.dart';
import '../base_view_model.dart';
import 'dart:developer' as developer;

/// ViewModel responsible for managing the blocked users list registry,
/// handling secondary list pagination, and performing structural unblock requests.
class BlockedUsersViewModel extends BaseViewModel {
  final SettingsRepository _settingsRepository;

  List<UserModel> _blockedUsers = [];
  List<UserModel> get blockedUsers => _blockedUsers;

  // Pagination states
  int _page = 1;
  final int _limit = 20;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  BlockedUsersViewModel({SettingsRepository? settingsRepository})
    : _settingsRepository = settingsRepository ?? SettingsRepository();

  /// Fetches the initial sequence of blacklisted user profiles from remote indices.
  /// Resets pagination checkpoints back to page 1.
  Future<bool> fetchBlockedUsers() async {
    _page = 1;
    _hasMore = true;
    _blockedUsers = [];

    return await runBusyFuture(() async {
          try {
            final result = await _settingsRepository.getBlockedUsers(
              page: _page,
              limit: _limit,
            );

            final paginatedResult = result.data;

            _blockedUsers = paginatedResult?.items ?? [];
            _hasMore =
                (paginatedResult?.page ?? 0) <
                (paginatedResult?.totalPages ?? 0);

            notifyListeners();
            return true;
          } catch (e) {
            developer.log(
              'BlockedUsersViewModel - fetchBlockedUsers() error: $e',
              name: 'BlockedUsersViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Appends older historically blacklisted user models using endless track buffers.
  Future<void> loadMoreBlockedUsers() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      _page += 1;

      final result = await _settingsRepository.getBlockedUsers(
        page: _page,
        limit: _limit,
      );

      final paginatedResult = result.data;

      _blockedUsers.addAll(paginatedResult?.items ?? []);
      _hasMore =
          (paginatedResult?.page ?? 0) < (paginatedResult?.totalPages ?? 0);

      notifyListeners();
    } catch (e) {
      developer.log(
        'BlockedUsersViewModel - loadMoreBlockedUsers() error: $e',
        name: 'BlockedUsersViewModel',
      );
      setError(e.toString());

      // Rollback page increment value upon encountering pipe collection dropouts
      _page = (_page > 1) ? _page - 1 : 1;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Dispatches an execution request to purge a user reference profile from the block list.
  Future<bool> unblockUser(String userId) async {
    return await runBusyFuture(() async {
          try {
            final result = await _settingsRepository.unblockUser(userId);
            final success = result.isSuccess;
            setSuccess(result.message);

            if (success) {
              // Synchronously updates layout records array instantly on network success
              _blockedUsers.removeWhere((user) => user.id == userId);
            }

            notifyListeners();
            return success;
          } catch (e) {
            developer.log(
              'BlockedUsersViewModel - unblockUser() error: $e',
              name: 'BlockedUsersViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }
}
