import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ngobrolin_app/core/enums/general_enums.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/utils/general_utils.dart';
import 'package:ngobrolin_app/core/viewmodels/auth/auth_view_model.dart';
import 'package:ngobrolin_app/core/viewmodels/chat/chat_view_model.dart';
import 'package:ngobrolin_app/core/viewmodels/search/search_user_view_model.dart';
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
  const CreateChatGroupScreen({super.key});

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
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _handleImageSelection() async {
    // Call the helper, file option is hidden by default
    final source = await MediaPickerModal.showMediaPickerBottomSheet(context);

    if (source == null) return;

    final imageSource = source.getImageSource;

    if (imageSource != null) _pickAndCropImage(imageSource);
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
        final croppedFile = await GeneralUtils.cropImage(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('new_group'))),
      floatingActionButton: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _groupNameController,
        builder: (context, value, child) {
          final isButtonDisabled = value.text.trim().isEmpty;

          return Selector<ChatViewModel, bool>(
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
                          final participantIds = context
                              .read<SearchUserViewModel>()
                              .selectedGroupMembers
                              .map((user) => user.id)
                              .toList();

                          final chatViewModel = context.read<ChatViewModel>();
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

                          final success = await chatViewModel
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

                            final searchUserViewModel = context
                                .read<SearchUserViewModel>();
                            searchUserViewModel.resetGroupSelection();
                            final conversationId = chatViewModel.conversationId;
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
      body: Selector<ChatViewModel, bool>(
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
                        setState(
                          () {},
                        ); // Update the state to show/hide the button
                      },
                    ),

                    const SizedBox(height: 16),
                    Selector<SearchUserViewModel, List<dynamic>>(
                      // Sesuaikan tipe List dengan model User kamu
                      selector: (context, viewModel) =>
                          viewModel.selectedGroupMembers,
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
                                // padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }
}
