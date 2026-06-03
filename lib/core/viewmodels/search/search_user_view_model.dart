import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../base_view_model.dart';

class SearchUserViewModel extends BaseViewModel {
  final UserRepository _userRepository;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> get users => _users;

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
            final userResults = await _userRepository.searchUsers(
              _searchQuery,
              page: _page,
              limit: _limit,
            );

            _users = userResults
                .map(
                  (user) => {
                    'id': user.id,
                    'name': user.name,
                    'username': user.username,
                    'bio': user.bio ?? '',
                    'avatarUrl': user.avatarUrl,
                    'isPrivate': user.isPrivate,
                  },
                )
                .toList();

            // Determine if more pages are available
            _hasMore = userResults.length == _limit;
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
      final userResults = await _userRepository.searchUsers(
        _searchQuery,
        page: _page,
        limit: _limit,
      );

      final mapped = userResults
          .map(
            (user) => {
              'id': user.id,
              'name': user.name,
              'username': user.username,
              'bio': user.bio ?? '',
              'avatarUrl': user.avatarUrl,
            },
          )
          .toList();

      _users.addAll(mapped);
      _hasMore = userResults.length == _limit;
    } catch (e) {
      setError(e.toString());
      // Rollback page increment on error
      _page = (_page > 1) ? _page - 1 : 1;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Gets user details by ID
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      setLoading(true);

      final user = await _userRepository.getUserById(userId);

      // Convert to map format for compatibility with existing UI
      final userMap = {
        'id': user.id,
        'name': user.name,
        'username': user.username,
        'bio': user.bio ?? '',
        'avatarUrl': user.avatarUrl,
      };

      return userMap;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }
}
