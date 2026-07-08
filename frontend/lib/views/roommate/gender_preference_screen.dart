import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../models/roommate_profile_model.dart';
import '../../widgets/roommate_option_screen.dart';

class GenderPreferenceScreen extends StatelessWidget {
  const GenderPreferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoommateQuizController>();
    return RoommateOptionScreen<RoommateGenderPreference>(
      currentStep: 12,
      title: 'Roommate Gender',
      subtitle: 'Who would you prefer to live with?',
      selectedValue: ctrl.profile.genderPreference,
      options: const [
        RoommateOption(label: 'Male', icon: Icons.male_rounded, value: RoommateGenderPreference.male),
        RoommateOption(label: 'Female', icon: Icons.female_rounded, value: RoommateGenderPreference.female),
        RoommateOption(label: 'Non-Binary', icon: Icons.transgender_rounded, value: RoommateGenderPreference.nonBinary),
        RoommateOption(label: 'Any', icon: Icons.diversity_3_rounded, value: RoommateGenderPreference.any),
      ],
      onSelect: ctrl.setGenderPreference,
      onBack: () => context.pop(),
      onContinue: () => context.push(AppRoutes.roommateRoomType),
    );
  }
}