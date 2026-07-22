import 'package:ngobrolin_app/core/models/conversation_model.dart';
import 'package:ngobrolin_app/core/repositories/chat_repository.dart';

import '../base_view_model.dart';
import 'dart:developer' as developer;

/// ViewModel responsible for executing remote user lookup requests,
/// filtering participant matches, and orchestrating list pagination.
class SearchGroupViewModel extends BaseViewModel {
  final ChatRepository _chatRepository;

  static const String _logName = 'SearchGroupViewModel';

  List<ConversationModel> _groups = [];
  List<ConversationModel> get groups => _groups;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Pagination states
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  SearchGroupViewModel({ChatRepository? chatRepository})
    : _chatRepository = chatRepository ?? ChatRepository();

  /// Sets the real-time search criteria string and resets query indices.
  void setSearchQuery({String query = ''}) {
    _searchQuery = query;
    _page = 1;
    _hasMore = true;

    searchGroups();
  }

  Future<bool> searchGroups() async {
    return await runBusyFuture(
          () async {
            final result = await _chatRepository.searchGroupConversations(
              _searchQuery,
              page: _page,
              limit: _limit,
            );

            final paginatedResult = result.data;
            final groupsResult = paginatedResult?.items ?? [];
            _groups = groupsResult;

            // Evaluates remote limits to determine additional sequential pages availability
            _hasMore =
                (paginatedResult?.page ?? 0) <
                (paginatedResult?.totalPages ?? 0);

            notifyListeners();
            return true;
          },
          logName: _logName,
          logContext: 'searchGroups()',
        ) ??
        false;
  }

  /// Appends supplementary search matching results down the collection index.
  Future<void> loadMoreSearchGroups() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _page += 1;
      final result = await _chatRepository.searchGroupConversations(
        _searchQuery,
        page: _page,
        limit: _limit,
      );

      final paginatedResult = result.data;
      final groupsResult = paginatedResult?.items ?? [];

      _groups.addAll(groupsResult);
      _hasMore =
          (paginatedResult?.page ?? 0) < (paginatedResult?.totalPages ?? 0);

      notifyListeners();
    } catch (e, stackTrace) {
      developer.log(
        'loadMoreSearchGroups() error: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      setError(e.toString());

      // Rollback current page pointer safely upon experiencing pipeline transmission drops
      _page = (_page > 1) ? _page - 1 : 1;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> joinGroupConversation({required String conversationId}) async {
    if (conversationId.isEmpty) {
      return false;
    }

    return await runBusyFuture(
          () async {
            final result = await _chatRepository.joinGroupConversation(
              conversationId: conversationId,
            );

            setSuccess(result.message);
            notifyListeners();
            return result.isSuccess;
          },
          logName: _logName,
          logContext: 'JoinGroupConversation()',
        ) ??
        false;
  }
}
