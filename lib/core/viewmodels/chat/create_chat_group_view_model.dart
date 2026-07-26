import 'package:ngobrolin_app/core/models/conversation_model.dart';
import 'package:ngobrolin_app/core/models/user_model.dart';
import 'package:ngobrolin_app/core/repositories/chat_repository.dart';
import 'package:ngobrolin_app/core/viewmodels/base_view_model.dart';

class CreateChatGroupViewModel extends BaseViewModel {
  final ChatRepository _chatRepository;

  static const String _logName = 'CreateChatGroupViewModel';

  ConversationModel? _newConversation;
  ConversationModel? get newConversation => _newConversation;

  List<UserModel> _selectedUsers = [];
  List<UserModel> get selectedUsers => _selectedUsers;

  List<String> get selectedUsersIds =>
      _selectedUsers.map((user) => user.id).toList();

  CreateChatGroupViewModel({ChatRepository? chatRepository})
    : _chatRepository = chatRepository ?? ChatRepository();

  void initCreateChatGroup({required List<UserModel> selectedUsers}) {
    _selectedUsers = selectedUsers;

    notifyListeners();
  }

  Future<bool> createGroupConversation({
    required String groupName,
    required List<String> participantIds,
    required String createdByUserId,
    String? groupImagePath,
  }) async {
    return await runBusyFuture(
          () async {
            String? groupImageUrl;
            if (groupImagePath != null && groupImagePath.isNotEmpty) {
              final result = await _chatRepository.uploadConversationGroupImage(
                filePath: groupImagePath,
              );
              groupImageUrl = result.data;
            }

            final result = await _chatRepository.createGroupConversation(
              groupName: groupName,
              participantIds: participantIds,
              groupImageUrl: groupImageUrl,
              createdByUserId: createdByUserId,
            );

            _newConversation = result.data;
            notifyListeners();
            return true;
          },
          logName: _logName,
          logContext: 'createGroupConversation()',
        ) ??
        false;
  }
}
