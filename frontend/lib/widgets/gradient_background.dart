import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Full-screen gradient background using the TRIBAL primary palette.
///
/// Wraps [child] inside a gradient [Container]. Used on onboarding screens
/// and as the top section of auth screens.
class GradientBackground extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;

  const GradientBackground({
    super.key,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}
