import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'custom_button.dart';
import 'profile_flow_header.dart';
import 'selection_card.dart';

class RoommateOption<T> {
  final String label;
  final IconData icon;
  final T value;
  const RoommateOption({required this.label, required this.icon, required this.value});
}

/// Shared layout for every single-choice quiz step (Smoking, Drinking,
/// Guests, Food, Pets, Study Habit, Gender Preference, Room Type).
/// Keeps `ProfileFlowHeader` + `SelectionCard` + `CustomButton` consistent
/// instead of re-implementing the same scaffold 8 times.
class RoommateOptionScreen<T> extends StatelessWidget {
  final int currentStep;
  final String title;
  final String subtitle;
  final List<RoommateOption<T>> options;
  final T? selectedValue;
  final ValueChanged<T> onSelect;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;
  final String continueLabel;

  const RoommateOptionScreen({
    super.key,
    required this.currentStep,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selectedValue,
    required this.onSelect,
    required this.onContinue,
    this.onBack,
    this.continueLabel = 'Next',
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
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                children: [
                  for (final option in options) ...[
                    SelectionCard(
                      label: option.label,
                      icon: option.icon,
                      isSelected: selectedValue == option.value,
                      onTap: () => onSelect(option.value),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 26),
                  CustomButton(
                    label: continueLabel,
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