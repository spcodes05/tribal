import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/profile_flow_header.dart';
import 'package:frontend/models/roommate_profile_model.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoommateQuizController>();
    final p = ctrl.profile;

    final rows = <MapEntry<String, String>>[
      MapEntry('Budget', 'Rs. ${p.budgetMin} – Rs. ${p.budgetMax}'),
      MapEntry('Sleep Schedule', p.sleepSchedule?.label ?? '—'),
      MapEntry('Wake Time', p.wakeTime?.format(context) ?? '—'),
      MapEntry('Smoking', p.smoking?.label ?? '—'),
      MapEntry('Drinking', p.drinking?.label ?? '—'),
      MapEntry('Cleanliness', '${p.cleanliness} / 5'),
      MapEntry('Noise Level', '${p.noiseLevel} / 5'),
      MapEntry('Guests', p.guestsPreference?.label ?? '—'),
      MapEntry('Food', p.foodPreference?.label ?? '—'),
      MapEntry('Pets', p.pets?.label ?? '—'),
      MapEntry('Study Habit', p.studyHabit?.label ?? '—'),
      MapEntry('Interests', p.interests.isEmpty ? 'None selected' : p.interests.join(', ')),
      MapEntry('Gender Preference', p.genderPreference.label),
      MapEntry('Room Type', p.roomTypePreference.label),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileFlowHeader(
              currentStep: 14,
              totalSteps: RoommateQuizController.totalSteps,
              title: 'Review Your Answers',
              subtitle: 'Make sure everything looks right',
              onBack: () => context.pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                children: [
                  for (final row in rows) ...[
                    _ReviewRow(label: row.key, value: row.value),
                    const Divider(color: AppColors.divider, height: 1),
                  ],
                  const SizedBox(height: 32),
                  CustomButton(
                    label: 'Confirm & Find Roommates',
                    isLoading: ctrl.isSubmitting,
                    suffix: const Icon(Icons.search_rounded, size: 18),
                    onTap: ctrl.isQuizComplete
                        ? () => context.push(AppRoutes.roommateFinding)
                        : null,
                  ),
                  if (!ctrl.isQuizComplete)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Please go back and answer every required question.',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent),
                      ),
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

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}