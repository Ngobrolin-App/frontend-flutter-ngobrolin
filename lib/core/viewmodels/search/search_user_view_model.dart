import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../base_view_model.dart';
import 'dart:developer' as developer;

/// ViewModel responsible for executing remote user lookup requests,
/// filtering participant matches, and orchestrating list pagination.
class SearchUserViewModel extends BaseViewModel {
  final UserRepository _userRepository;

  List<UserModel> _users = [];
  List<UserModel> get users => _users;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Pagination states
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  SearchUserViewModel({UserRepository? userRepository})
    : _userRepository = userRepository ?? UserRepository();

  /// Sets the real-time search criteria string and resets query indices.
  void setSearchQuery(String query) {
    _searchQuery = query;
    _page = 1;
    _hasMore = true;

    searchUsers();
  }

  /// Queries the API engine to gather matching user records matching page 1.
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

            // Evaluates remote limits to determine additional sequential pages availability
            _hasMore =
                (paginatedResult?.page ?? 0) <
                (paginatedResult?.totalPages ?? 0);

            notifyListeners();
            return true;
          } catch (e) {
            developer.log(
              'SearchUserViewModel - searchUsers() error: $e',
              name: 'SearchUserViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Appends supplementary search matching results down the collection index.
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

      notifyListeners();
    } catch (e) {
      developer.log(
        'SearchUserViewModel - loadMoreSearchUser() error: $e',
        name: 'SearchUserViewModel',
      );
      setError(e.toString());

      // Rollback current page pointer safely upon experiencing pipeline transmission drops
      _page = (_page > 1) ? _page - 1 : 1;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
