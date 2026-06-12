import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Animated dot-style page indicator for the onboarding flow.
///
/// Active dot is wider and uses the brand color; inactive dots are small
/// and semi-transparent white (designed to sit on the dark gradient).
class OnboardingIndicator extends StatelessWidget {
  final int pageCount;
  final int currentIndex;

  const OnboardingIndicator({
    super.key,
    required this.pageCount,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
