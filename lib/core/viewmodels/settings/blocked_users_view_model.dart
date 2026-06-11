import '../../models/user_model.dart';
import '../../repositories/settings_repository.dart';
import '../base_view_model.dart';

class BlockedUsersViewModel extends BaseViewModel {
  final SettingsRepository _settingsRepository;

  List<UserModel> _blockedUsers = [];
  List<UserModel> get blockedUsers => _blockedUsers;

  // Pagination state
  int _page = 1;
  final int _limit = 20;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  BlockedUsersViewModel({SettingsRepository? settingsRepository})
    : _settingsRepository = settingsRepository ?? SettingsRepository();

  /// Fetches the list of blocked users (first page)
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
            // print(
            //   'Fetched blocked users: ${_blockedUsers.length}, hasMore: $_hasMore, page: ${result.page}, limit: ${result.limit}, total: ${result.total}, totalPages: ${result.totalPages}, ',
            // ); // Debug log

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

      final result = await _settingsRepository.getBlockedUsers(
        page: _page,
        limit: _limit,
      );

      final paginatedResult = result.data;

      _blockedUsers.addAll(paginatedResult?.items ?? []);
      _hasMore =
          (paginatedResult?.page ?? 0) < (paginatedResult?.totalPages ?? 0);
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
            final result = await _settingsRepository.unblockUser(userId);
            final success = result.isSuccess;
            setSuccess(result.message);
            if (success) {
              _blockedUsers.removeWhere((user) => user.id == userId);
            }
            return success;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }
}
