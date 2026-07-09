import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/enums/general_enums.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/models/conversation_participant_model.dart';
import 'package:ngobrolin_app/core/viewmodels/chat/group_profile_view_model.dart';
import 'package:ngobrolin_app/core/widgets/cards/app_avatar.dart';
import 'package:ngobrolin_app/core/widgets/cards/user_list_item.dart';
import 'package:ngobrolin_app/core/widgets/texts/expandable_text_section.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_colors.dart';
import 'dart:developer' as developer;

class GroupProfileScreen extends StatefulWidget {
  final String conversationId;

  const GroupProfileScreen({super.key, required this.conversationId});

  @override
  State<GroupProfileScreen> createState() => _GroupProfileScreenState();
}

class _GroupProfileScreenState extends State<GroupProfileScreen> {
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<GroupProfileViewModel>().loadMoreParticipants();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            const Divider(height: 1, thickness: 1, color: AppColors.lightGrey),

            // Header List Anggota
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Anggota Grup',
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
                    return _ParticipantItemRow(index: index);
                  },
                );
              },
            ),

            // Indikator Loading Tambahan saat Pagination Aktif
            Selector<GroupProfileViewModel, bool>(
              selector: (_, vm) => vm.isLoadingMoreParticipants,
              builder: (context, isLoadingMore, _) {
                if (!isLoadingMore) return const SizedBox(height: 20);
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget Khusus Row Partisipan bersandar pada Selector Spesifik Indeks.
/// Mencegah seluruh baris list ikut berkedip/rebuild jika hanya ada satu baris yang mengalami update data.
class _ParticipantItemRow extends StatelessWidget {
  final int index;

  const _ParticipantItemRow({required this.index});

  @override
  Widget build(BuildContext context) {
    return Selector<GroupProfileViewModel, ConversationParticipantModel>(
      selector: (_, vm) => vm.conversationParticipants[index],
      builder: (context, participant, _) {
        final user = participant.user;
        if (user == null) return const SizedBox.shrink();

        return UserListItem(
          user: user,
          onTap: () {
            // 6. Micro-Rebuild: Menggunakan context.read() agar event click tidak memicu penataan ulang layout
            final currentVm = context.read<GroupProfileViewModel>();
            developer.log(
              'Melihat profil anggota: ${user.name} di grup ${currentVm.conversationName}',
            );
          },
        );
      },
    );
  }
}
