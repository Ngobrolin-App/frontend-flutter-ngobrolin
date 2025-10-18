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
            _users = userResults
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

            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  /// Searches for users with dummy data for testing purposes
  Future<bool> searchUsersDummy() async {
    return await runBusyFuture(() async {
          try {
            // Create dummy user data
            final dummyUsers = [
              User(
                id: '1',
                username: 'johndoe',
                name: 'John Doe',
                bio: 'Software Developer passionate about Flutter and mobile development',
                avatarUrl: 'https://via.placeholder.com/150',
                isPrivate: false,
                createdAt: DateTime.now().subtract(const Duration(days: 30)),
                updatedAt: DateTime.now().subtract(const Duration(days: 1)),
              ),
              User(
                id: '2',
                username: 'janesmith',
                name: 'Jane Smith',
                bio: 'UI/UX Designer | Creating beautiful and intuitive user experiences',
                avatarUrl: 'https://via.placeholder.com/150',
                isPrivate: false,
                createdAt: DateTime.now().subtract(const Duration(days: 45)),
                updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
              ),
              User(
                id: '3',
                username: 'mikejohnson',
                name: 'Mike Johnson',
                bio: 'Full Stack Developer | React, Node.js, Flutter enthusiast',
                avatarUrl: null,
                isPrivate: false,
                createdAt: DateTime.now().subtract(const Duration(days: 60)),
                updatedAt: DateTime.now().subtract(const Duration(days: 2)),
              ),
              User(
                id: '4',
                username: 'sarahwilson',
                name: 'Sarah Wilson',
                bio: 'Product Manager | Building amazing products that users love',
                avatarUrl: 'https://via.placeholder.com/150',
                isPrivate: true,
                createdAt: DateTime.now().subtract(const Duration(days: 20)),
                updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
              ),
              User(
                id: '5',
                username: 'davidbrown',
                name: 'David Brown',
                bio: 'Mobile App Developer | iOS & Android | Coffee lover ☕',
                avatarUrl: null,
                isPrivate: false,
                createdAt: DateTime.now().subtract(const Duration(days: 90)),
                updatedAt: DateTime.now().subtract(const Duration(days: 3)),
              ),
              User(
                id: '6',
                username: 'emilydavis',
                name: 'Emily Davis',
                bio: 'Data Scientist | Machine Learning | Python & R',
                avatarUrl: 'https://via.placeholder.com/150',
                isPrivate: false,
                createdAt: DateTime.now().subtract(const Duration(days: 15)),
                updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
              ),
              User(
                id: '7',
                username: 'alexchen',
                name: 'Alex Chen',
                bio: 'DevOps Engineer | Cloud Infrastructure | Kubernetes expert',
                avatarUrl: null,
                isPrivate: false,
                createdAt: DateTime.now().subtract(const Duration(days: 75)),
                updatedAt: DateTime.now().subtract(const Duration(days: 1)),
              ),
              User(
                id: '8',
                username: 'lisagarcia',
                name: 'Lisa Garcia',
                bio: 'Frontend Developer | React & Vue.js | Design systems advocate',
                avatarUrl: 'https://via.placeholder.com/150',
                isPrivate: false,
                createdAt: DateTime.now().subtract(const Duration(days: 40)),
                updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
              ),
            ];

            List<User> filteredUsers;

            if (_searchQuery.isEmpty) {
              // If search query is empty, return all dummy users
              filteredUsers = dummyUsers;
            } else {
              // Filter users based on search query (name or username)
              filteredUsers = dummyUsers.where((user) {
                final query = _searchQuery.toLowerCase();
                return user.name.toLowerCase().contains(query) ||
                    user.username.toLowerCase().contains(query) ||
                    (user.bio?.toLowerCase().contains(query) ?? false);
              }).toList();
            }

            // Convert to map format for compatibility with existing UI
            _users = filteredUsers
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

            return true;
          } catch (e) {
            setError(e.toString());
            return false;
          }
        }) ??
        false;
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
