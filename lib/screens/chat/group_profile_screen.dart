import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/models/conversation_participant_model.dart';
import 'package:ngobrolin_app/core/providers/socket_provider.dart';
import 'package:ngobrolin_app/core/viewmodels/auth/auth_view_model.dart';
import 'package:ngobrolin_app/core/viewmodels/chat/group_profile_view_model.dart';
import 'package:ngobrolin_app/core/widgets/buttons/load_more_list_button.dart';
import 'package:ngobrolin_app/core/widgets/cards/action_list_tile.dart';
import 'package:ngobrolin_app/core/widgets/cards/app_avatar.dart';
import 'package:ngobrolin_app/core/widgets/cards/user_list_item.dart';
import 'package:ngobrolin_app/core/widgets/texts/expandable_text_section.dart';
import 'package:ngobrolin_app/routes/app_routes.dart';
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

  late SocketProvider _socketProvider;

  @override
  void initState() {
    super.initState();
    // Inisialisasi data dijalankan secara micro-task / post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProfileViewModel>().initGroupProfile(
        conversationId: widget.conversationId,
      );
    });

    // Menggunakan context.read() untuk mendengarkan perubahan scroll pagination tanpa memicu rebuild global
    // _scrollController.addListener(() {
    //   if (_scrollController.position.pixels >=
    //       _scrollController.position.maxScrollExtent - 200) {
    //     context.read<GroupProfileViewModel>().loadMoreParticipants();
    //   }
    // });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    developer.log('leavegroup - $success', name: 'WWWWW');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Profil Grup'), elevation: 0),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Micro-Rebuild: Avatar Kelompok Terisolasi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.primary,
              child: Selector<GroupProfileViewModel, (String?, String?)>(
                selector: (_, vm) =>
                    (vm.conversationImageUrl, vm.conversationName),
                builder: (context, data, _) {
                  final imageUrl = data.$1;
                  final name = data.$2;
                  return Column(
                    children: [
                      AppAvatar(
                        imageUrl: imageUrl,
                        name: name,
                        radius: 50,
                        fontSize: 40,
                        backgroundColor: AppColors.white,
                      ),

                      const SizedBox(height: 16),

                      // 2. Micro-Rebuild: Nama Kelompok Terisolasi
                      Selector<GroupProfileViewModel, String?>(
                        selector: (_, vm) => vm.conversationName,
                        builder: (context, name, _) {
                          return Text(
                            name ?? '',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
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
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
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
                                  args: {
                                    'number': totalParticipants.toString(),
                                  },
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),

            // 3. Micro-Rebuild: Deskripsi Kelompok Terisolasi
            Selector<GroupProfileViewModel, String?>(
              selector: (_, vm) => vm.conversationDescription,
              builder: (context, description, _) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: ExpandableTextSection(
                    title: context.tr('group_description'),
                    content: description ?? '',
                  ),
                );
              },
            ),
            const Divider(height: 1),

            // Header List Anggota
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
                        '$total Orang',
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

            // 4. Micro-Rebuild: Mengunci Rebuild ListView hanya bersandar pada .length
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
