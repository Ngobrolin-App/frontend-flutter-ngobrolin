import 'package:ngobrolin_app/core/enums/general_enums.dart';
import 'package:ngobrolin_app/core/models/conversation_model.dart';
import 'package:ngobrolin_app/core/models/conversation_participant_model.dart';
import 'package:ngobrolin_app/core/models/user_model.dart';
import 'package:ngobrolin_app/core/repositories/chat_repository.dart';
import 'package:ngobrolin_app/core/viewmodels/base_view_model.dart';
import 'dart:developer' as developer;

class GroupProfileViewModel extends BaseViewModel {
  final ChatRepository _chatRepository;

  ConversationModel? _conversation;
  ConversationModel? get conversation => _conversation;

  String? _conversationId;
  String? get conversationId => _conversationId;

  String? _conversationType;
  String? get conversationType => _conversationType;

  String? _conversationName;
  String? get conversationName => _conversationName;

  String? _conversationGroupImage;
  String? get conversationGroupImage => _conversationGroupImage;

  // --- TAMBAHAN STATE UNTUK MICRO-REBUILDS DESKRIPSI ---
  String? _conversationDescription;
  String? get conversationDescription => _conversationDescription;

  int _totalParticipants = 0;
  int get totalParticipants => _totalParticipants;

  List<ConversationParticipantModel> _conversationParticipants = [];
  List<ConversationParticipantModel> get conversationParticipants =>
      _conversationParticipants;

  int get countLoadedConversationParticipants =>
      _conversationParticipants.length;

  final int _limit = 5;
  int _pageParticipants = 1;
  bool _hasMoreParticipants = true;
  bool get hasMoreParticipants => _hasMoreParticipants;
  bool _isLoadingMoreParticipants = false;
  bool get isLoadingMoreParticipants => _isLoadingMoreParticipants;

  GroupProfileViewModel({ChatRepository? chatRepository})
    : _chatRepository = chatRepository ?? ChatRepository();

  void initGroupProfile({required String conversationId}) async {
    _conversationId = conversationId;
    _pageParticipants = 1;
    _hasMoreParticipants = true;

    if (_conversationId != null && _conversationId!.isNotEmpty) {
      await _getConversationDataOnly();
      await fetchParticipants();
    }
  }

  Future<bool> _getConversationDataOnly() async {
    if (_conversationId == null) return false;

    return await runBusyFuture(() async {
          try {
            final result = await _chatRepository.getConversationById(
              conversationId: _conversationId!,
              isShowParticipants: true,
            );
            final conversation = result.data;

            _conversation = conversation;

            _conversationType = conversation?.type;
            _conversationName = conversation?.name;
            _conversationDescription = conversation?.groupDescription;

            if (conversation?.type == ConversationType.group.name) {
              _conversationGroupImage = conversation?.groupImage;
            }

            notifyListeners();
            return true;
          } catch (e) {
            developer.log(
              "GroupProfileViewModel - _getConversationDataOnly() error $e",
              name: 'GroupProfileViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  // Fetches participants metadata linked inside the room roster array.
  Future<bool> fetchParticipants() async {
    if (_conversationId == null) return false;

    return await runBusyFuture(() async {
          try {
            final result = await _chatRepository.getConversationParticipants(
              page: _pageParticipants,
              limit: _limit,
              conversationId: _conversationId!,
              isIncludeMe: _conversationType != ConversationType.private.name,
            );

            final paginatedResult = result.data;
            _totalParticipants = paginatedResult?.total ?? 0;

            final participantList = paginatedResult?.items ?? [];

            _conversationParticipants = participantList;
            _hasMoreParticipants =
                (paginatedResult?.page ?? 0) <
                (paginatedResult?.totalPages ?? 0);

            notifyListeners();
            return true;
          } catch (e) {
            developer.log(
              "GroupProfileViewModel - fetchParticipants() error $e",
              name: 'ChatViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  // Fetches participants metadata linked inside the room roster array.
  Future<bool> loadMoreParticipants() async {
    if (!_hasMoreParticipants ||
        isLoading ||
        _isLoadingMoreParticipants ||
        _conversationId == null) {
      return false;
    }

    _isLoadingMoreParticipants = true;
    notifyListeners();

    return await runBusyFuture(() async {
          try {
            _pageParticipants += 1;
            final result = await _chatRepository.getConversationParticipants(
              page: _pageParticipants,
              limit: _limit,
              conversationId: _conversationId!,
              isIncludeMe: _conversationType != ConversationType.private.name,
            );

            final paginatedResult = result.data;
            final participantList = paginatedResult?.items ?? [];

            _conversationParticipants.addAll(participantList);
            _hasMoreParticipants =
                (paginatedResult?.page ?? 0) <
                (paginatedResult?.totalPages ?? 0);

            _isLoadingMoreParticipants = false;
            notifyListeners();
            return true;
          } catch (e) {
            developer.log(
              "GroupProfileViewModel - fetchParticipants() error $e",
              name: 'ChatViewModel',
            );
            _pageParticipants -= 1;
            _isLoadingMoreParticipants = false;
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  Future<bool> leaveConversation({required String? conversationId}) async {
    if (conversationId == null || conversationId.isEmpty) return false;

    return await runBusyFuture(() async {
          try {
            var success = true;

            final result = await _chatRepository.leaveConversation(
              conversationId: conversationId,
            );
            success = result.isSuccess;
            setSuccess(result.message);

            notifyListeners();
            return success;
          } catch (e) {
            developer.log(
              "GroupProfileViewModel - leaveConversation() error $e",
              name: 'GroupProfileViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }

  Future<bool> updateConversation({
    String? name,
    String? groupImagePath,
    String? groupDescription,
  }) async {
    if (_conversationId == null) return false;

    return await runBusyFuture(() async {
          try {
            String? groupImageUrl;

            // Section A: Evaluates and updates textual parameters or password credentials
            if (groupImagePath != null) {
              final result = await _chatRepository.uploadConversationGroupImage(
                filePath: groupImagePath,
              );

              groupImageUrl = result.data;
            }
            if (name != null ||
                groupDescription != null ||
                groupImageUrl != null) {
              final result = await _chatRepository.updateConversation(
                conversationId: _conversationId!,
                name: name,
                groupDescription: groupDescription,
                groupImageUrl: groupImageUrl,
              );

              _conversation = result.data;

              _conversationName = _conversation?.name;
              _conversationDescription = _conversation?.groupDescription;
              _conversationGroupImage = _conversation?.groupImage;

              setSuccess(result.message);
            }

            notifyListeners();
            return true;
          } catch (e) {
            developer.log(
              "GroupProfileViewModel - updateConversation() error $e",
              name: 'GroupProfileViewModel',
            );
            setError(e.toString());
            return false;
          }
        }) ??
        false;
  }
}
