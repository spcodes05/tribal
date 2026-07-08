import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/roommate_scale_slider.dart';

class NoiseLevelScreen extends StatelessWidget {
  const NoiseLevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoommateQuizController>();
    return RoommateScaleSlider(
      currentStep: 6,
      title: 'Noise Level',
      subtitle: 'How much noise are you okay with at home?',
      lowLabel: 'Very Quiet',
      highLabel: 'Very Lively',
      value: ctrl.profile.noiseLevel,
      onChanged: ctrl.setNoiseLevel,
      onBack: () => context.pop(),
      onContinue: () => context.push(AppRoutes.roommateGuests),
    );
  }
}