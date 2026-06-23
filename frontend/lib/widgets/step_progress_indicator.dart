import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

/// "Step X of N" progress indicator used across the profile completion flow
/// (Phone Verification, Gender Selection, Social Verification, Profile Setup).
///
/// Renders a thin segmented bar plus a small text label, designed to sit on
/// the brand gradient background — matching the visual language of
/// [OnboardingIndicator] but communicating linear (not cyclical) progress.
class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $currentStep of $totalSteps',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.85),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(totalSteps, (index) {
            final isCompleted = index < currentStep;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: index == totalSteps - 1 ? 0 : 6,
                ),
                height: 4,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.white
                      : Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
