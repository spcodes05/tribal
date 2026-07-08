import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../models/roommate_profile_model.dart';
import '../../widgets/roommate_option_screen.dart';

class PetsScreen extends StatelessWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoommateQuizController>();
    return RoommateOptionScreen<PetsPreference>(
      currentStep: 9,
      title: 'Pets',
      subtitle: 'Do you have or want pets at home?',
      selectedValue: ctrl.profile.pets,
      options: const [
        RoommateOption(label: 'I Have Pets', icon: Icons.pets_rounded, value: PetsPreference.hasPets),
        RoommateOption(label: 'No Pets', icon: Icons.not_interested_rounded, value: PetsPreference.noPets),
        RoommateOption(label: 'Okay With Pets', icon: Icons.favorite_outline_rounded, value: PetsPreference.okayWithPets),
        RoommateOption(label: 'Not Okay With Pets', icon: Icons.block_rounded, value: PetsPreference.notOkayWithPets),
      ],
      onSelect: ctrl.setPets,
      onBack: () => context.pop(),
      onContinue: ctrl.profile.pets != null ? () => context.push(AppRoutes.roommateStudyHabit) : null,
    );
  }
}