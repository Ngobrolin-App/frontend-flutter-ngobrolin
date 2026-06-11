import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../base_view_model.dart';

class SearchUserViewModel extends BaseViewModel {
  final UserRepository _userRepository;

  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Pagination state
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  SearchUserViewModel({UserRepository? userRepository})
    : _userRepository = userRepository ?? UserRepository();

  /// Sets the search query and triggers a search
  void setSearchQuery(String query) {
    _searchQuery = query;
    // Reset pagination when query changes
    _page = 1;
    _hasMore = true;
    searchUsers();
  }

  /// Searches for users based on the current query (first page)
  Future<bool> searchUsers() async {
    return await runBusyFuture(() async {
          try {
            final result = await _userRepository.searchUsers(
              _searchQuery,
              page: _page,
              limit: _limit,
            );

            final paginatedResult = result.data;

            final userResults = paginatedResult?.items ?? [];
            _users = userResults;

            // Determine if more pages are available
            _hasMore =
                (paginatedResult?.page ?? 0) <
                (paginatedResult?.totalPages ?? 0);
            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Loads next page and appends to list
  Future<void> loadMoreSearchUser() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      _page += 1;
      final result = await _userRepository.searchUsers(
        _searchQuery,
        page: _page,
        limit: _limit,
      );

      final paginatedResult = result.data;
      final userResults = paginatedResult?.items ?? [];

      _users.addAll(userResults);
      _hasMore =
          (paginatedResult?.page ?? 0) < (paginatedResult?.totalPages ?? 0);
    } catch (e) {
      setError(e.toString());
      // Rollback page increment on error
      _page = (_page > 1) ? _page - 1 : 1;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
