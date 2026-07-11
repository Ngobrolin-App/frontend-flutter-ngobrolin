import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';
import 'package:ngobrolin_app/core/utils/general_utils.dart';
import 'package:ngobrolin_app/core/viewmodels/settings/settings_view_model.dart';

class ChatDateBadge extends StatelessWidget {
  final DateTime date;

  const ChatDateBadge({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    // OPTIMASI: Hanya listen perubahan languageCode demi efisiensi render
    final localeCode = context.select<SettingsViewModel, String>(
      (vm) => vm.locale.languageCode,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        GeneralUtils.getChatDateHeader(date, context, localeCode: localeCode),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
      ),
    );
  }
}
