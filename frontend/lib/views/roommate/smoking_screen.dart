import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../models/roommate_profile_model.dart';
import '../../widgets/roommate_option_screen.dart';

class SmokingScreen extends StatelessWidget {
  const SmokingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoommateQuizController>();
    return RoommateOptionScreen<SmokingPreference>(
      currentStep: 3,
      title: 'Smoking Habits',
      subtitle: 'Are you okay living with a smoker?',
      selectedValue: ctrl.profile.smoking,
      options: const [
        RoommateOption(label: 'Non-Smoker', icon: Icons.smoke_free_rounded, value: SmokingPreference.nonSmoker),
        RoommateOption(label: 'Smoker', icon: Icons.smoking_rooms_rounded, value: SmokingPreference.smoker),
        RoommateOption(label: 'Occasional', icon: Icons.local_fire_department_outlined, value: SmokingPreference.occasional),
      ],
      onSelect: ctrl.setSmoking,
      onBack: () => context.pop(),
      onContinue: ctrl.profile.smoking != null ? () => context.push(AppRoutes.roommateDrinking) : null,
    );
  }
}