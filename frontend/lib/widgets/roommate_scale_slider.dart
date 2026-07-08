import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import 'custom_button.dart';
import 'profile_flow_header.dart';

/// Generic 1–5 scale picker matching the `PositiveSmallIntegerField`
/// (MinValueValidator(1), MaxValueValidator(5)) used by both
/// `cleanliness` and `noise_level` in the backend model.
class RoommateScaleSlider extends StatelessWidget {
  final int currentStep;
  final String title;
  final String subtitle;
  final String lowLabel;
  final String highLabel;
  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  const RoommateScaleSlider({
    super.key,
    required this.currentStep,
    required this.title,
    required this.subtitle,
    required this.lowLabel,
    required this.highLabel,
    required this.value,
    required this.onChanged,
    required this.onContinue,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileFlowHeader(
              currentStep: currentStep,
              totalSteps: 14,
              title: title,
              subtitle: subtitle,
              onBack: onBack,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
              child: Column(
                children: [
                  Text(
                    '$value',
                    style: GoogleFonts.poppins(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Slider(
                    value: value.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.inputBorder,
                    onChanged: (v) => onChanged(v.round()),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(lowLabel,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary)),
                      Text(highLabel,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    label: 'Next',
                    suffix: const Icon(Icons.arrow_forward, size: 18),
                    onTap: onContinue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}