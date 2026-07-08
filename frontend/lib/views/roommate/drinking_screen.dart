import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../models/roommate_profile_model.dart';
import '../../widgets/roommate_option_screen.dart';

class DrinkingScreen extends StatelessWidget {
  const DrinkingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoommateQuizController>();
    return RoommateOptionScreen<DrinkingPreference>(
      currentStep: 4,
      title: 'Drinking Habits',
      subtitle: 'How do you feel about alcohol at home?',
      selectedValue: ctrl.profile.drinking,
      options: const [
        RoommateOption(label: 'Non-Drinker', icon: Icons.no_drinks_outlined, value: DrinkingPreference.nonDrinker),
        RoommateOption(label: 'Drinker', icon: Icons.liquor_outlined, value: DrinkingPreference.drinker),
        RoommateOption(label: 'Social Drinker', icon: Icons.wine_bar_outlined, value: DrinkingPreference.social),
      ],
      onSelect: ctrl.setDrinking,
      onBack: () => context.pop(),
      onContinue: ctrl.profile.drinking != null ? () => context.push(AppRoutes.roommateCleanliness) : null,
    );
  }
}