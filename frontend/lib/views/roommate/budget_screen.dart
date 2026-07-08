import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/profile_flow_header.dart';

/// Step 1 of 14. Feeds `score_budget()` in scoring.py — weight 20, the
/// single heaviest-weighted factor, so overlap accuracy matters here.
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoommateQuizController>();
    RangeValues range = RangeValues(
      ctrl.profile.budgetMin.toDouble(),
      ctrl.profile.budgetMax.toDouble(),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileFlowHeader(
              currentStep: 1,
              totalSteps: RoommateQuizController.totalSteps,
              title: 'What\'s your budget?',
              subtitle: 'Monthly rent range you\'re comfortable with (NPR)',
              onBack: () => context.pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
              child: Column(
                children: [
                  Text(
                    'Rs. ${range.start.round()} – Rs. ${range.end.round()}',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  RangeSlider(
                    values: range,
                    min: 2000,
                    max: 50000,
                    divisions: 96,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.inputBorder,
                    labels: RangeLabels('Rs. ${range.start.round()}', 'Rs. ${range.end.round()}'),
                    onChanged: (v) => ctrl.setBudget(v.start.round(), v.end.round()),
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    label: 'Next',
                    suffix: const Icon(Icons.arrow_forward, size: 18),
                    onTap: ctrl.isBudgetValid
                        ? () => context.push(AppRoutes.roommateSleepSchedule)
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