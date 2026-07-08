import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/roommate_quiz_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../models/roommate_profile_model.dart';
import '../../widgets/roommate_option_screen.dart';

class RoomTypePreferenceScreen extends StatelessWidget {
  const RoomTypePreferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RoommateQuizController>();
    return RoommateOptionScreen<RoomTypePreference>(
      currentStep: 13,
      title: 'Room Type',
      subtitle: 'What kind of space are you looking for?',
      selectedValue: ctrl.profile.roomTypePreference,
      options: const [
        RoommateOption(label: 'Private Room', icon: Icons.meeting_room_outlined, value: RoomTypePreference.privateRoom),
        RoommateOption(label: 'Shared Room', icon: Icons.bed_outlined, value: RoomTypePreference.sharedRoom),
        RoommateOption(label: 'Entire Place', icon: Icons.house_outlined, value: RoomTypePreference.entirePlace),
        RoommateOption(label: 'Any', icon: Icons.apartment_outlined, value: RoomTypePreference.any),
      ],
      onSelect: ctrl.setRoomTypePreference,
      onBack: () => context.pop(),
      continueLabel: 'Review Answers',
      onContinue: () => context.push(AppRoutes.roommateReview),
    );
  }
}