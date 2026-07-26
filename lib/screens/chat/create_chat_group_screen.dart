import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ngobrolin_app/core/enums/general_enums.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/models/user_model.dart';
import 'package:ngobrolin_app/core/utils/media_utils.dart';
import 'package:ngobrolin_app/core/utils/permission_utils.dart';
import 'package:ngobrolin_app/core/viewmodels/auth/auth_view_model.dart';
import 'package:ngobrolin_app/core/viewmodels/chat/create_chat_group_view_model.dart';
import 'package:ngobrolin_app/core/widgets/buttons/app_icon_button.dart';
import 'package:ngobrolin_app/core/widgets/buttons/primary_button.dart';
import 'package:ngobrolin_app/core/widgets/cards/app_avatar.dart';
import 'package:ngobrolin_app/core/widgets/cards/circle_user_item.dart';
import 'package:ngobrolin_app/core/widgets/inputs/custom_text_field.dart';
import 'package:ngobrolin_app/core/widgets/modals/media_picker_modal.dart';
import 'package:ngobrolin_app/routes/app_routes.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';
import 'package:provider/provider.dart';

class CreateChatGroupScreen extends StatefulWidget {
  final List<UserModel> selectedUsers;
  const CreateChatGroupScreen({super.key, required this.selectedUsers});

  @override
  State<CreateChatGroupScreen> createState() => _CreateChatGroupScreenState();
}

class _CreateChatGroupScreenState extends State<CreateChatGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  late final TextEditingController _groupNameController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CreateChatGroupViewModel>().initCreateChatGroup(
        selectedUsers: widget.selectedUsers,
      );
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _handleImageSelection() async {
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
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1080,
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
            _imageFile = croppedFile;
          });
        }
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

  Future<bool> _showPopDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('discard_changes')),
        content: Text(dialogContext.tr('are_you_sure_discard')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('no')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              dialogContext.tr('yes'),
              style: const TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final hasChanges =
            _groupNameController.text.trim().isNotEmpty || _imageFile != null;

        if (hasChanges) {
          final shouldPop = await _showPopDialog(context);
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop(result);
          }
        } else {
          if (context.mounted) {
            Navigator.of(context).pop(result);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(context.tr('new_group'))),
        floatingActionButton: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _groupNameController,
          builder: (context, value, child) {
            final isButtonDisabled = value.text.trim().isEmpty;
            return Selector<CreateChatGroupViewModel, bool>(
              selector: (_, vm) => vm.isLoading,
              builder: (context, isLoading, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PrimaryButton(
                    text: context.tr('create_new_group'),
                    isLoading: isLoading,
                    onPressed: isButtonDisabled || isLoading
                        ? null
                        : () async {
                            final createChatGroupViewModel = context
                                .read<CreateChatGroupViewModel>();
                            final participantIds =
                                createChatGroupViewModel.selectedUsersIds;
                            final authViewModel = context.read<AuthViewModel>();
                            final currentUserId = authViewModel.currentUserId;
                            if (currentUserId == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.tr('createdbyuserid_required'),
                                    ),
                                    backgroundColor: AppColors.warning,
                                  ),
                                );
                              }
                              return;
                            }
                            final success = await createChatGroupViewModel
                                .createGroupConversation(
                                  groupName: _groupNameController.text.trim(),
                                  participantIds: participantIds,
                                  groupImagePath: _imageFile?.path,
                                  createdByUserId: currentUserId,
                                );
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.tr('create_group_success'),
                                  ),
                                  backgroundColor: AppColors.accent,
                                ),
                              );
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.main,
                                (route) => false,
                              );
                              final conversationId =
                                  createChatGroupViewModel.newConversation?.id;
                              if (conversationId != null) {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.chat,
                                  arguments: {'chatId': conversationId},
                                );
                              }
                            } else if (!success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.tr('create_group_failed'),
                                  ),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                            }
                          },
                  ),
                );
              },
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: Selector<CreateChatGroupViewModel, bool>(
          selector: (_, vm) => vm.isLoading,
          builder: (context, isLoading, _) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            AppAvatar(
                              localFile: _imageFile,
                              radius: 60,
                              fontSize: 50,
                              backgroundColor: AppColors.lightGrey,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: AppIconButton(
                                onTap: _handleImageSelection,
                                icon: const Iconify(
                                  MaterialSymbols.android_camera,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _groupNameController,
                        labelText: context.tr('group_name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('please_enter_group_name');
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      Selector<CreateChatGroupViewModel, List<dynamic>>(
                        selector: (context, viewModel) =>
                            viewModel.selectedUsers,
                        builder: (context, selectedMembers, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${context.tr('members')}: ${selectedMembers.length}',
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 100,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: selectedMembers.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 4),
                                  itemBuilder: (context, index) {
                                    final user = selectedMembers[index];
                                    return CircleUserItem(user: user);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
