import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';

class ActionListTile extends StatelessWidget {
  final String title;
  final Color titleColor;
  final String icon;
  final Color iconColor;
  final bool iconHaveBackground;

  final VoidCallback onTap;

  const ActionListTile({
    super.key,
    required this.title,
    this.titleColor = AppColors.text,
    required this.icon,
    this.iconColor = AppColors.white,
    this.iconHaveBackground = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: (iconHaveBackground)
                  ? AppColors.primary
                  : AppColors.transparent,
              child: Iconify(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
