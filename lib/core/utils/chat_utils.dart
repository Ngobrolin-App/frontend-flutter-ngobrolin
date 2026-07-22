import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/models/message_model.dart';
import 'package:intl/intl.dart';

class ChatUtils {
  static String getChatDateHeader(
    DateTime messageDate,
    BuildContext context, {
    String localeCode = 'en',
    bool useNumericFormat = false,
    bool showTodayTime = false,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Normalisasi jam/menit/detik dari messageDate untuk perbandingan yang akurat
    final normalizedMessageDate = DateTime(
      messageDate.year,
      messageDate.month,
      messageDate.day,
    );

    if (normalizedMessageDate == today) {
      // Jika showTodayTime true, kembalikan jam dan menit
      if (showTodayTime) {
        // Gunakan 'HH:mm' untuk format 24 jam (misal: 15:30)
        // Gunakan 'hh:mm a' jika ingin format 12 jam (misal: 03:30 PM)
        return context.loc.formatTime(messageDate);
      }
      return context.tr('today');
    } else if (normalizedMessageDate == yesterday) {
      return context.tr('yesterday');
    } else if (now.difference(normalizedMessageDate).inDays < 7) {
      // Menampilkan nama hari (misal: "Senin" jika locale 'id', "Monday" jika 'en')
      return DateFormat('EEEE', localeCode).format(messageDate);
    } else {
      // Menampilkan tanggal penuh sesuai opsi yang dipilih
      if (useNumericFormat) {
        // Hasil: 29/06/2026
        return DateFormat('dd/MM/yyyy', localeCode).format(messageDate);
      } else {
        // Hasil: 29 Juni 2026 (jika locale 'id') atau 29 June 2026 (jika locale 'en')
        return DateFormat('d MMMM y', localeCode).format(messageDate);
      }
    }
  }

  static String getSystemMessageText(
    MessageModel message,
    BuildContext context,
  ) {
    final systemMetadata = message.systemMetadata ?? {};
    final systemEventType = message.systemEventType;

    // Ekstraksi nilai seragam berdasarkan Kontrak Blueprint
    final String actorName = systemMetadata['actorName'] ?? 'Someone';
    final String addedUserNames =
        systemMetadata['addedUserNames'] ?? 'Some people';
    final String targetName = systemMetadata['targetName'] ?? 'someone';
    final String groupName = systemMetadata['groupName'] ?? 'Group';
    final String groupDescription =
        systemMetadata['groupDescription'] ?? 'Group Description';

    switch (systemEventType) {
      case 'GROUP_CREATED':
        return context.tr(
          'system_msg_group_created',
          args: {'actorName': actorName, 'groupName': groupName},
        );

      case 'USER_JOINED':
        return context.tr(
          'system_msg_user_joined',
          args: {'actorName': actorName},
        );

      case 'USERS_ADDED':
        return context.tr(
          'system_msg_user_added',
          args: {'actorName': actorName, 'targetName': addedUserNames},
        );

      case 'GROUP_IMAGE_CHANGED':
        return context.tr(
          'system_msg_image_changed',
          args: {'actorName': actorName},
        );

      case 'GROUP_NAME_CHANGED':
        return context.tr(
          'system_msg_name_changed',
          args: {'actorName': actorName, 'groupName': groupName},
        );

      case 'GROUP_DESCRIPTION_CHANGED':
        return context.tr(
          'system_msg_description_changed',
          args: {
            'actorName': actorName,
            'groupName': groupName,
            'groupDescription': groupDescription,
          },
        );

      case 'USER_REMOVED':
        return context.tr(
          'system_msg_user_removed',
          args: {'actorName': actorName, 'targetName': targetName},
        );

      case 'USER_LEFT':
        return context.tr(
          'system_msg_user_left',
          args: {'actorName': actorName},
        );

      default:
        // Fallback: Jika ada event baru dari backend namun aplikasi versi user belum di-update
        return message.content ?? '';
    }
  }
}
