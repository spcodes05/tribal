import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/profile_setup_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../models/onboarding_profile_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/profile_flow_header.dart';
import '../../widgets/selection_card.dart';

/// Step 2 of 4 — Gender Selection.
///
/// Single-select list using [SelectionCard]. Selection drives the smart
/// matching algorithm's compatibility scoring described in the project
/// proposal (Section 3.3.1).
class GenderSelectionScreen extends StatelessWidget {
  const GenderSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProfileSetupController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileFlowHeader(
              currentStep: 2,
              totalSteps: 4,
              title: AppStrings.genderSelectionTitle,
              subtitle: AppStrings.genderSelectionSubtitle,
              onBack: () => context.pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                children: [
                  SelectionCard(
                    label: AppStrings.genderMale,
                    icon: Icons.male_rounded,
                    isSelected: ctrl.profile.gender == Gender.male,
                    onTap: () => ctrl.selectGender(Gender.male),
                  ),
                  const SizedBox(height: 14),
                  SelectionCard(
                    label: AppStrings.genderFemale,
                    icon: Icons.female_rounded,
                    isSelected: ctrl.profile.gender == Gender.female,
                    onTap: () => ctrl.selectGender(Gender.female),
                  ),
                  const SizedBox(height: 14),
                  SelectionCard(
                    label: AppStrings.genderNonBinary,
                    icon: Icons.transgender_rounded,
                    isSelected: ctrl.profile.gender == Gender.nonBinary,
                    onTap: () => ctrl.selectGender(Gender.nonBinary),
                  ),
                  const SizedBox(height: 14),
                  SelectionCard(
                    label: AppStrings.genderPreferNotToSay,
                    icon: Icons.visibility_off_outlined,
                    isSelected: ctrl.profile.gender == Gender.preferNotToSay,
                    onTap: () => ctrl.selectGender(Gender.preferNotToSay),
                  ),

                  const SizedBox(height: 40),

                  CustomButton(
                    label: AppStrings.nextLabel,
                    suffix: const Icon(Icons.arrow_forward, size: 18),
                    onTap: ctrl.isGenderSelected
                        ? () => context.push(AppRoutes.socialVerification)
                        : null,
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
