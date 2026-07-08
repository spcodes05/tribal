import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/roommate_profile_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/interest_chip.dart';
import '../../widgets/profile_flow_header.dart';

/// Step 11 of 14. Feeds `score_interests()` — Jaccard similarity, weight 6.
class InterestsScreen extends StatelessWidget {
  const InterestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoommateQuizController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileFlowHeader(
              currentStep: 11,
              totalSteps: RoommateQuizController.totalSteps,
              title: 'Your Interests',
              subtitle: 'Pick a few things you\'re into — optional but improves matches',
              onBack: () => context.pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kRoommateInterestOptions.map((interest) {
                      return InterestChip(
                        label: interest,
                        isSelected: ctrl.isInterestSelected(interest),
                        onTap: () => ctrl.toggleInterest(interest),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    label: 'Next',
                    suffix: const Icon(Icons.arrow_forward, size: 18),
                    onTap: () => context.push(AppRoutes.roommateGenderPreference),
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