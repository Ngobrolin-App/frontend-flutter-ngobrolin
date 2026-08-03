import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ngobrolin_app/core/enums/general_enums.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/models/conversation_participant_model.dart';
import 'package:ngobrolin_app/core/providers/socket_provider.dart';
import 'package:ngobrolin_app/core/utils/media_utils.dart';
import 'package:ngobrolin_app/core/utils/permission_utils.dart';
import 'package:ngobrolin_app/core/viewmodels/auth/auth_view_model.dart';
import 'package:ngobrolin_app/core/viewmodels/chat/group_profile_view_model.dart';
import 'package:ngobrolin_app/core/viewmodels/search/search_user_view_model.dart';
import 'package:ngobrolin_app/core/widgets/buttons/load_more_list_button.dart';
import 'package:ngobrolin_app/core/widgets/cards/action_list_tile.dart';
import 'package:ngobrolin_app/core/widgets/cards/app_avatar.dart';
import 'package:ngobrolin_app/core/widgets/cards/user_list_item.dart';
import 'package:ngobrolin_app/core/widgets/modals/media_picker_modal.dart';
import 'package:ngobrolin_app/core/widgets/states/image_error_placeholder.dart';
import 'package:ngobrolin_app/core/widgets/texts/expandable_text_section.dart';
import 'package:ngobrolin_app/routes/app_routes.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';

import 'dart:developer' as developer;

class GroupProfileScreen extends StatefulWidget {
  final String conversationId;

  const GroupProfileScreen({super.key, required this.conversationId});

  @override
  State<GroupProfileScreen> createState() => _GroupProfileScreenState();
}

class _GroupProfileScreenState extends State<GroupProfileScreen> {
  final ScrollController _scrollController = ScrollController();

  File? _groupImageFile;

  late SocketProvider _socketProvider;

  late Function(dynamic) _conversationUpdatedHandler;
  late Function(dynamic) _leftParticipantHandler;
  late Function(dynamic) _participantsAddedHandler;
  late Function(dynamic) _participantJoinedHandler;

  @override
  void initState() {
    super.initState();
    // Inisialisasi data dijalankan secara micro-task / post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProfileViewModel>().initGroupProfile(
        conversationId: widget.conversationId,
      );

      _setupSocketHandlers();
    });
  }

  void _setupSocketHandlers() {
    _socketProvider = Provider.of<SocketProvider>(context, listen: false);

    final groupProfileViewModel = context.read<GroupProfileViewModel>();

    _conversationUpdatedHandler = (data) {
      groupProfileViewModel.handleConversationUpdated(data);
    };

    _leftParticipantHandler = (data) {
      groupProfileViewModel.handleLeftParticipant(data);
    };

    _participantsAddedHandler = (data) {
      groupProfileViewModel.handleParticipantsAdded(data);
    };

    _participantJoinedHandler = (data) {
      groupProfileViewModel.handleParticipantJoined(data);
    };

    _socketProvider.on('conversation_updated', _conversationUpdatedHandler);
    _socketProvider.on('left_participant', _leftParticipantHandler);
    _socketProvider.on('participants_added', _participantsAddedHandler);
    _socketProvider.on('participant_joined', _participantJoinedHandler);
  }

  @override
  void dispose() {
    _scrollController.dispose();

    try {
      _socketProvider.off('conversation_updated', _conversationUpdatedHandler);
      _socketProvider.off('left_participant', _leftParticipantHandler);
      _socketProvider.off('participants_added', _participantsAddedHandler);
      _socketProvider.off('participant_joined', _participantJoinedHandler);
    } catch (e) {
      developer.log(
        'GroupProfileScreen - dispose() - Error unregistering socket: $e',
        name: 'ChatScreen',
      );
    }

    super.dispose();
  }

  void _showLeaveGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('leave_group')),
        content: Text(dialogContext.tr('are_you_sure_leave_group')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.tr('no')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _leaveGroup();
            },
            child: Text(
              dialogContext.tr('yes'),
              style: const TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  void _leaveGroup() async {
    final groupProfileViewModel = context.read<GroupProfileViewModel>();

    final conversationId = groupProfileViewModel.conversationId;

    if (conversationId == null || (conversationId.isEmpty) || !mounted) {
      return;
    }

    final success = await groupProfileViewModel.leaveConversation(
      conversationId: conversationId,
    );

    if (success) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              groupProfileViewModel.successMessage ?? 'leave_group_success',
            ),
          ),
          backgroundColor: AppColors.accent,
        ),
      );
      _socketProvider.leaveConversationSocket(
        groupProfileViewModel.conversationId!,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              groupProfileViewModel.errorMessage ?? 'leave_group_failed',
            ),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _navigateToEditName(String currentName) {
    Navigator.pushNamed(
      context,
      AppRoutes.textEditor,
      arguments: {
        'title': context.tr('group_name'),
        'initialValue': currentName,
        'maxLength': 100,
        'maxLines': 1,
      },
    ).then((newValue) {
      if (newValue != null && newValue != currentName) {
        if (!mounted) return;

        final groupProfileViewModel = context.read<GroupProfileViewModel>();

        groupProfileViewModel.updateConversation(name: newValue as String);
      }
    });
  }

  void _navigateToEditDescription(String currentDesc) {
    Navigator.pushNamed(
      context,
      AppRoutes.textEditor,
      arguments: {
        'title': context.tr('group_description'),
        'initialValue': currentDesc,
        'maxLength': 500,
        'maxLines': null,
        'description': context.tr('group_description_visibility'),
        'keyboardType': TextInputType.multiline,
      },
    ).then((newValue) {
      if (newValue != null && newValue != currentDesc) {
        if (!mounted) return;

        final groupProfileViewModel = context.read<GroupProfileViewModel>();

        groupProfileViewModel.updateConversation(
          groupDescription: newValue as String,
        );
      }
    });
  }

  void _handleProfileTap() async {
    final groupProfileViewModel = context.read<GroupProfileViewModel>();
    final groupProfileImage = groupProfileViewModel.conversationGroupImage;
    final tappedOption = await MediaPickerModal.showProfileTapOptionModal(
      context,
      viewProfileImageEnabled:
          (groupProfileImage != null) && (groupProfileImage.isNotEmpty),
    );

    if (tappedOption == ProfileTapOption.viewProfileImage) {
      if (!mounted) return;

      Navigator.pushNamed(
        context,
        AppRoutes.fullscreenImage,
        arguments: {
          'imageUrl': groupProfileImage ?? '',
          'showDownloadButton': false,
        },
      );
    } else {
      _handleImageSelection();
    }
  }

  void _handleImageSelection() async {
    // Call the helper, file option is hidden by default
    final source = await MediaPickerModal.showMediaPickerBottomSheet(context);

    if (source == null) return;
    bool isGranted = false;

    if (source == MediaSource.camera) {
      if (!mounted) return;
      isGranted = await PermissionUtils.checkAndRequestCamera(context);
    } else if (source == MediaSource.gallery) {
      if (!mounted) return;
      isGranted = await PermissionUtils.checkAndRequestMedia(context);
    }
    if (isGranted) {
      final imageSource = source.getImageSource;

      if (imageSource != null) _pickAndCropImage(imageSource);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('permission_denied')),
          backgroundColor: AppColors.warning, // Assuming warning is red/orange
        ),
      );
    }
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1080, // Resolusi aman sebelum di-crop
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        final croppedFile = await MediaUtils.cropImage(
          sourcePath: pickedFile.path,
          title: context.tr('edit_profile'),
          isSquare: true,
        );

        if (croppedFile != null && mounted) {
          setState(() {
            _groupImageFile = croppedFile;
          });
        }

        if (_groupImageFile != null) _saveGroupImageProfile();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('failed_to_pick_image')),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<void> _saveGroupImageProfile() async {
    try {
      final groupProfileViewModel = context.read<GroupProfileViewModel>();

      var success = false;
      if (_groupImageFile != null && _groupImageFile?.path != null) {
        success = await groupProfileViewModel.updateConversation(
          groupImagePath: _groupImageFile!.path,
        );
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                groupProfileViewModel.successMessage ??
                    'conversation_group_image_update_success',
              ),
            ),
            backgroundColor: AppColors.accent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                groupProfileViewModel.errorMessage ??
                    'conversation_group_image_update_failed',
              ),
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(e.toString())),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Profil Grup'), elevation: 0),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.primary,
              child: Column(
                children: [
                  Selector<GroupProfileViewModel, (String?, String?)>(
                    selector: (_, vm) =>
                        (vm.conversationGroupImage, vm.conversationName),
                    builder: (context, data, _) {
                      final imageUrl = data.$1;
                      final name = data.$2;
                      return GestureDetector(
                        onTap: _handleProfileTap,
                        child: AppAvatar(
                          localFile: _groupImageFile,
                          imageUrl: imageUrl,
                          name: name,
                          radius: 50,
                          fontSize: 40,
                          backgroundColor: AppColors.white,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  Selector<GroupProfileViewModel, String?>(
                    selector: (_, vm) => vm.conversationName,
                    builder: (context, name, _) {
                      return GestureDetector(
                        onTap: () => _navigateToEditName(name ?? ''),
                        child: Text(
                          name ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  Selector<GroupProfileViewModel, (String?, int?)>(
                    selector: (_, vm) =>
                        (vm.conversationType, vm.totalParticipants),
                    builder: (context, data, _) {
                      final conversationType = data.$1;
                      final totalParticipants = data.$2 ?? 0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr(conversationType ?? 'group'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8.0),
                            width: 4.0,
                            height: 4.0,
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            context.tr(
                              'number_of_members',
                              args: {'number': totalParticipants.toString()},
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            Selector<GroupProfileViewModel, String?>(
              selector: (_, vm) => vm.conversationDescription,
              builder: (context, description, _) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ExpandableTextSection(
                        title: context.tr('group_description'),
                        content: description ?? '',
                        onEdit: () =>
                            _navigateToEditDescription(description ?? ''),
                        emptyContentWidget: GestureDetector(
                          onTap: () => _navigateToEditDescription(''),
                          child: Text(
                            context.tr('add_group_description'),
                            style: const TextStyle(color: AppColors.accent),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Text(
                    context.tr('members'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  Selector<GroupProfileViewModel, int>(
                    selector: (_, vm) => vm.totalParticipants,
                    builder: (context, total, _) {
                      return Text(
                        context.tr(
                          'number_of_people',
                          args: {'number': total.toString()},
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            ActionListTile(
              title: context.tr('add_members'),
              icon: MaterialSymbols.person_add_rounded,
              onTap: () async {
                final groupProfileViewModel = context
                    .read<GroupProfileViewModel>();

                final existingParticipants =
                    groupProfileViewModel.conversationParticipantsIds;

                final result = await Navigator.pushNamed(
                  context,
                  AppRoutes.searchUser,
                  arguments: {
                    'userSelectionAction': UserSelectionAction.addNewMembers,
                    'excludeUsers': existingParticipants,
                  },
                );

                if (result != null &&
                    result is List<String> &&
                    result.isNotEmpty) {
                  if (!mounted) return;

                  final selectedUserIds = result;

                  final success = await groupProfileViewModel
                      .addConversationParticipants(
                        newParticipanstIds: selectedUserIds,
                      );

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr(
                          success
                              ? (groupProfileViewModel.successMessage ??
                                    'add_member_success')
                              : (groupProfileViewModel.errorMessage ??
                                    'add_member_failed'),
                        ),
                      ),
                      backgroundColor: success
                          ? AppColors.accent
                          : AppColors.warning,
                    ),
                  );
                }
              },
            ),

            Selector<GroupProfileViewModel, int>(
              selector: (_, vm) => vm.countLoadedConversationParticipants,
              builder: (context, totalLoaded, _) {
                if (totalLoaded == 0) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalLoaded,
                  itemBuilder: (context, index) {
                    // 5. Micro-Rebuild: Item didelegasikan ke Widget Khusus Berbasis Indeks
                    return Selector<
                      GroupProfileViewModel,
                      ConversationParticipantModel
                    >(
                      selector: (_, vm) => vm.conversationParticipants[index],
                      builder: (context, participant, _) {
                        final user = participant.user;
                        if (user == null) return const SizedBox.shrink();

                        return UserListItem(
                          user: user,
                          onTap: () {
                            final authViewModel = context.read<AuthViewModel>();
                            if (authViewModel.currentUserId == user.id) return;
                            Navigator.of(context).pushNamed(
                              AppRoutes.userProfile,
                              arguments: {'userId': user.id},
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),

            Selector<GroupProfileViewModel, (bool, bool)>(
              selector: (_, vm) =>
                  (vm.hasMoreParticipants, vm.isLoadingMoreParticipants),
              builder: (context, data, _) {
                final hasMore = data.$1;
                final isLoadingMore = data.$2;

                // Tombol akan hilang sepenuhnya jika hasMore bernilai false
                if (!hasMore) return const SizedBox(height: 24);

                return Center(
                  child: LoadMoreListButton(
                    isLoading: isLoadingMore,
                    onPressed: () {
                      // Memanggil API tanpa perlu stateful rebuild
                      context
                          .read<GroupProfileViewModel>()
                          .loadMoreParticipants();
                    },
                  ),
                );
              },
            ),

            Divider(height: 1),

            ActionListTile(
              title: context.tr('leave_group'),
              titleColor: AppColors.warning,
              iconHaveBackground: false,
              icon: MaterialSymbols.logout,
              iconColor: AppColors.warning,
              onTap: () {
                _showLeaveGroupDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
