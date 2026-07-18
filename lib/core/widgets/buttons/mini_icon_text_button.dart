import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class MiniIconTextButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget? icon;
  final String? text;

  const MiniIconTextButton({
    super.key,
    required this.onTap,
    this.icon,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              if (text != null) const SizedBox(width: 6),
            ],
            if (text != null)
              Text(
                text!,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
