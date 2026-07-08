import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../models/roommate_profile_model.dart';
import '../../widgets/roommate_option_screen.dart';

class FoodPreferenceScreen extends StatelessWidget {
  const FoodPreferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoommateQuizController>();
    return RoommateOptionScreen<FoodPreference>(
      currentStep: 8,
      title: 'Food Preference',
      subtitle: 'What do you usually cook or eat at home?',
      selectedValue: ctrl.profile.foodPreference,
      options: const [
        RoommateOption(label: 'Vegetarian', icon: Icons.eco_outlined, value: FoodPreference.vegetarian),
        RoommateOption(label: 'Non-Vegetarian', icon: Icons.set_meal_outlined, value: FoodPreference.nonVegetarian),
        RoommateOption(label: 'Vegan', icon: Icons.grass_outlined, value: FoodPreference.vegan),
        RoommateOption(label: 'No Preference', icon: Icons.restaurant_outlined, value: FoodPreference.noPreference),
      ],
      onSelect: ctrl.setFoodPreference,
      onBack: () => context.pop(),
      onContinue: ctrl.profile.foodPreference != null ? () => context.push(AppRoutes.roommatePets) : null,
    );
  }
}