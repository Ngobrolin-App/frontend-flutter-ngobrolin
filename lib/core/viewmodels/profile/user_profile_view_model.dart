import 'package:ngobrolin_app/core/models/block_user_status.dart';
import 'package:ngobrolin_app/core/models/conversation_model.dart';

import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/settings_repository.dart';
import '../base_view_model.dart';
import 'dart:developer' as developer;

/// ViewModel responsible for inspecting external peer profiles and managing targeting features
/// like blocking or unblocking corresponding users.
class UserProfileViewModel extends BaseViewModel {
  final UserRepository _userRepository;
  final SettingsRepository _settingsRepository;

  static const String _logName = 'UserProfileViewModel';

  String? _userId;
  String? get userId => _userId;

  UserModel? _user;
  UserModel? get user => _user;

  bool _isBlocked = false;
  bool get isBlocked => _isBlocked;

  BlockUserStatus? _blockUserStatus;
  BlockUserStatus? get blockUserStatus => _blockUserStatus;

  List<ConversationModel> _groupsInCommon = [];
  List<ConversationModel> get groupsInCommon => _groupsInCommon;

  int get countLoadedGroupsInCommon => _groupsInCommon.length;

  int _totalGroupsInCommon = 0;
  int get totalGroupsInCommon => _totalGroupsInCommon;

  final int _limit = 5;
  int _pageGroupsInCommon = 1;
  bool _hasMoreGroupsInCommon = false;
  bool get hasMoreGroupsInCommon => _hasMoreGroupsInCommon;

  bool _isLoadingGroupsInCommon = false;
  bool get isLoadingGroupsInCommon => _isLoadingGroupsInCommon;

  UserProfileViewModel({
    UserRepository? userRepository,
    SettingsRepository? settingsRepository,
  }) : _userRepository = userRepository ?? UserRepository(),
       _settingsRepository = settingsRepository ?? SettingsRepository();

  void initUserProfile({required String userId}) async {
    _userId = userId;
    _pageGroupsInCommon = 1;
    _hasMoreGroupsInCommon = false;

    if (_userId != null && _userId!.isNotEmpty) {
      await fetchUserProfile();
      await getBlockUserStatus();
      await fetchGroupsInCommon();
    }
  }

  /// Fetches standard user profile metrics and evaluates target relationship blocks.
  Future<bool> fetchUserProfile() async {
    if (_userId == null || (userId?.isEmpty ?? true)) return false;
    return await runBusyFuture(
          () async {
            final result = await _userRepository.getUserById(_userId!);
            _user = result.data;

            notifyListeners();
            return true;
          },
          logName: _logName,
          logContext: 'fetchUserProfile()',
        ) ??
        false;
  }

  Future<bool> getBlockUserStatus() async {
    return await runBusyFuture(
          () async {
            try {
              final resultBlockUserStatus = await _settingsRepository
                  .getBlockUserStatus(user!.id);
              _blockUserStatus = resultBlockUserStatus.data;
              _isBlocked =
                  ((_blockUserStatus?.isBlocked ?? false) &&
                  (_blockUserStatus?.isBlockedByMe ?? false));

              notifyListeners();
              return true;
            } catch (e, stackTrace) {
              developer.log(
                'getBlockUserStatus - error: $e',
                name: _logName,
                error: e,
                stackTrace: stackTrace,
              );
              _blockUserStatus = null;
              _isBlocked = false;
              notifyListeners();

              setError(e.toString());
              return false;
            }
          },
          logName: _logName,
          logContext: 'getBlockUserStatus()',
        ) ??
        false;
  }

  void resetBlockStatus() {
    _blockUserStatus = null;
    _isBlocked = false;
    notifyListeners();
  }

  /// Registers a block flag against the focused user account index.
  Future<bool> blockUser() async {
    if (_user == null) return false;
    return await runBusyFuture(
          () async {
            final result = await _settingsRepository.blockUser(_user!.id);
            final success = result.isSuccess;

            if (success) {
              setSuccess(result.message);
              _isBlocked = true;
            }

            notifyListeners();
            return success;
          },
          logName: _logName,
          logContext: 'blockUser()',
        ) ??
        false;
  }

  /// Removes a block flag constraint targeting the focused user account instance.
  Future<bool> unblockUser() async {
    if (_user == null) return false;
    return await runBusyFuture(
          () async {
            final result = await _settingsRepository.unblockUser(_user!.id);
            final success = result.isSuccess;

            if (success) {
              setSuccess(result.message);
              _isBlocked = false;
            }

            notifyListeners();
            return success;
          },
          logName: _logName,
          logContext: 'unblockUser()',
        ) ??
        false;
  }

  /// Proxy wrapper switch mapping to toggle user structural blockage boundaries seamlessly.
  Future<bool> toggleBlockUser() async {
    if (_isBlocked) {
      return await unblockUser();
    } else {
      return await blockUser();
    }
  }

  Future<bool> fetchGroupsInCommon() async {
    if (_userId == null) return false;

    return await runBusyFuture(
          () async {
            final result = await _userRepository.getGroupsInCommon(
              page: _pageGroupsInCommon,
              limit: _limit,
              userId: _userId!,
            );

            final paginatedResult = result.data;
            _totalGroupsInCommon = paginatedResult?.total ?? 0;
            _groupsInCommon = paginatedResult?.items ?? [];
            _hasMoreGroupsInCommon =
                (paginatedResult?.page ?? 0) <
                (paginatedResult?.totalPages ?? 0);

            notifyListeners();
            return true;
          },
          logName: _logName,
          logContext: 'fetchGroupsInCommon()',
        ) ??
        false;
  }

  // Fetches participants metadata linked inside the room roster array.
  Future<bool> loadMoreGroupsInCommon() async {
    if (!_hasMoreGroupsInCommon ||
        isLoading ||
        _isLoadingGroupsInCommon ||
        _userId == null) {
      return false;
    }

    _isLoadingGroupsInCommon = true;
    notifyListeners();

    try {
      _pageGroupsInCommon += 1;
      final result = await _userRepository.getGroupsInCommon(
        page: _pageGroupsInCommon,
        limit: _limit,
        userId: _userId!,
      );

      final paginatedResult = result.data;
      _totalGroupsInCommon = paginatedResult?.total ?? 0;
      _groupsInCommon.addAll(paginatedResult?.items ?? []);
      _hasMoreGroupsInCommon =
          (paginatedResult?.page ?? 0) < (paginatedResult?.totalPages ?? 0);

      return true;
    } catch (e, stackTrace) {
      developer.log(
        "loadMoreParticipants() error $e",
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      _pageGroupsInCommon = (_pageGroupsInCommon > 1)
          ? _pageGroupsInCommon - 1
          : 1;
      setError(e.toString());
      return false;
    } finally {
      _isLoadingGroupsInCommon = false;
      notifyListeners();
    }
  }
}
