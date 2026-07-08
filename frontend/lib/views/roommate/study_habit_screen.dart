import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../models/roommate_profile_model.dart';
import '../../widgets/roommate_option_screen.dart';

class StudyHabitScreen extends StatelessWidget {
  const StudyHabitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoommateQuizController>();
    return RoommateOptionScreen<StudyHabit>(
      currentStep: 10,
      title: 'Study Habit',
      subtitle: 'How do you usually study at home?',
      selectedValue: ctrl.profile.studyHabit,
      options: const [
        RoommateOption(label: 'Needs Quiet', icon: Icons.volume_off_outlined, value: StudyHabit.quiet),
        RoommateOption(label: 'Background Noise Okay', icon: Icons.headphones_outlined, value: StudyHabit.backgroundNoiseOk),
        RoommateOption(label: 'Group Study', icon: Icons.groups_outlined, value: StudyHabit.groupStudy),
        RoommateOption(label: 'Rarely Studies At Home', icon: Icons.school_outlined, value: StudyHabit.rarelyStudiesAtHome),
      ],
      onSelect: ctrl.setStudyHabit,
      onBack: () => context.pop(),
      onContinue: ctrl.profile.studyHabit != null ? () => context.push(AppRoutes.roommateInterests) : null,
    );
  }
}