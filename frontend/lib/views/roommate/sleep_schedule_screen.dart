import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/roommate_profile_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/profile_flow_header.dart';
import '../../widgets/selection_card.dart';

/// Step 2 of 14. Feeds `score_sleep_schedule()` — weight 15 (schedule
/// match 70% + wake-time closeness 30%, per scoring.py).
class SleepScheduleScreen extends StatelessWidget {
  const SleepScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoommateQuizController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileFlowHeader(
              currentStep: 2,
              totalSteps: RoommateQuizController.totalSteps,
              title: 'Sleep Schedule',
              subtitle: 'When are you most active?',
              onBack: () => context.pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                children: [
                  for (final s in SleepSchedule.values) ...[
                    SelectionCard(
                      label: s.label,
                      icon: s == SleepSchedule.earlyBird
                          ? Icons.wb_sunny_outlined
                          : s == SleepSchedule.nightOwl
                          ? Icons.nightlight_round
                          : Icons.access_time_rounded,
                      isSelected: ctrl.profile.sleepSchedule == s,
                      onTap: () => ctrl.setSleepSchedule(s),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 8),
                  _WakeTimeTile(
                    time: ctrl.profile.wakeTime,
                    onPick: (t) => ctrl.setWakeTime(t),
                  ),
                  const SizedBox(height: 26),
                  CustomButton(
                    label: 'Next',
                    suffix: const Icon(Icons.arrow_forward, size: 18),
                    onTap: ctrl.isSleepScheduleValid
                        ? () => context.push(AppRoutes.roommateSmoking)
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

class _WakeTimeTile extends StatelessWidget {
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay> onPick;

  const _WakeTimeTile({required this.time, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? const TimeOfDay(hour: 7, minute: 0),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.alarm_rounded, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                time == null ? 'Set your usual wake-up time' : 'Wakes up at ${time!.format(context)}',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}