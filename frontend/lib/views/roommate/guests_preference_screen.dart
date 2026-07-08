import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../models/roommate_profile_model.dart';
import '../../widgets/roommate_option_screen.dart';

class GuestsPreferenceScreen extends StatelessWidget {
  const GuestsPreferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoommateQuizController>();
    return RoommateOptionScreen<GuestsPreference>(
      currentStep: 7,
      title: 'Guests',
      subtitle: 'How often do you have friends over?',
      selectedValue: ctrl.profile.guestsPreference,
      options: const [
        RoommateOption(label: 'Rarely', icon: Icons.door_front_door_outlined, value: GuestsPreference.rarely),
        RoommateOption(label: 'Sometimes', icon: Icons.people_alt_outlined, value: GuestsPreference.sometimes),
        RoommateOption(label: 'Frequently', icon: Icons.celebration_outlined, value: GuestsPreference.frequently),
      ],
      onSelect: ctrl.setGuestsPreference,
      onBack: () => context.pop(),
      onContinue: ctrl.profile.guestsPreference != null ? () => context.push(AppRoutes.roommateFood) : null,
    );
  }
}