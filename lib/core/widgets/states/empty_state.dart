import 'package:flutter/material.dart';
import 'package:ngobrolin_app/core/localization/app_localizations.dart';
import 'package:ngobrolin_app/core/widgets/buttons/primary_button.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final Widget? image;
  final String? title;
  final String? subtitle;

  final bool showButton;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    this.image,
    this.title,
    this.subtitle,
    this.showButton = false,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            image ??
                Image.asset(
                  'assets/empty_state/img-empty-state.png',
                  width: 120,
                  height: 120,
                ),

            const SizedBox(height: 16),

            Text(
              title ?? context.tr('no_content'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            if (subtitle != null)
              Text(
                subtitle ?? context.tr('no_content'),
                style: const TextStyle(fontSize: 14, color: AppColors.grey),
              ),

            if (showButton) ...[
              const SizedBox(height: 24),

              PrimaryButton(
                text: buttonText ?? '',
                onPressed: onButtonPressed,
                isFullWidth: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
