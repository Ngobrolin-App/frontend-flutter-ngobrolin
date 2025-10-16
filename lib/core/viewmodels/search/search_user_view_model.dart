import '../../models/user.dart';
import '../../repositories/user_repository.dart';
import '../base_view_model.dart';

class SearchUserViewModel extends BaseViewModel {
  final UserRepository _userRepository;
  
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> get users => _users;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  SearchUserViewModel({UserRepository? userRepository}) 
      : _userRepository = userRepository ?? UserRepository();

  /// Sets the search query and triggers a search
  void setSearchQuery(String query) {
    _searchQuery = query;
    searchUsers();
  }

  /// Searches for users based on the current query
  Future<bool> searchUsers() async {
    return await runBusyFuture(() async {
      try {
        List<User> userResults;
        
        if (_searchQuery.isEmpty) {
          // If search query is empty, return random users
          userResults = await _userRepository.getRandomUsers();
        } else {
          // Search users based on query
          userResults = await _userRepository.searchUsers(_searchQuery);
        }
        
        // Convert to map format for compatibility with existing UI
        _users = userResults.map((user) => {
          'id': user.id,
          'name': user.name,
          'username': user.username,
          'bio': user.bio ?? '',
          'avatarUrl': user.avatarUrl,
        }).toList();
        
        return true;
      } catch (e) {
        setError(e.toString());
        return false;
      }
    }) ?? false;
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