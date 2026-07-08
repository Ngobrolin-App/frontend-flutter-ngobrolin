import 'package:flutter/material.dart';
import 'package:ngobrolin_app/theme/app_colors.dart';

class AppIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.backgroundColor = AppColors.accent,
    this.padding = const EdgeInsets.all(8),
    this.shape = BoxShape.circle, // Default shape is circle
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the border radius for both the box (if rectangle) and the splash effect
    final appliedBorderRadius = shape == BoxShape.rectangle
        ? (borderRadius ?? BorderRadius.circular(8))
        : null;

    // Use a large radius for the circular splash effect to ensure it covers the circle
    final splashRadius = shape == BoxShape.circle
        ? BorderRadius.circular(100)
        : appliedBorderRadius;

    // Using Ink ensures the background color is drawn on the Material canvas,
    // allowing the InkWell splash effect to render perfectly on top of it.
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: shape,
        borderRadius: appliedBorderRadius,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: splashRadius,
        child: Padding(padding: padding, child: icon),
      ),
    );
  }
}
