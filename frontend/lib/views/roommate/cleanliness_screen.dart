import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/roommate_scale_slider.dart';

class CleanlinessScreen extends StatelessWidget {
  const CleanlinessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoommateQuizController>();
    return RoommateScaleSlider(
      currentStep: 5,
      title: 'Cleanliness',
      subtitle: 'How tidy do you keep shared spaces?',
      lowLabel: 'Relaxed',
      highLabel: 'Spotless',
      value: ctrl.profile.cleanliness,
      onChanged: ctrl.setCleanliness,
      onBack: () => context.pop(),
      onContinue: () => context.push(AppRoutes.roommateNoiseLevel),
    );
  }
}