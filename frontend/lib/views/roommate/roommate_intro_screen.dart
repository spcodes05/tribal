import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/gradient_background.dart';

class RoommateIntroScreen extends StatelessWidget {
  const RoommateIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.groups_2_rounded, color: Colors.white, size: 84),
                const SizedBox(height: 28),
                Text(
                  'Find Your Ideal\nRoommate',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Answer a quick 14-question quiz so we can match you with roommates who fit your lifestyle — budget, sleep habits, cleanliness and more.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withOpacity(0.85), height: 1.5),
                ),
                const SizedBox(height: 40),
                CustomButtonLight(
                  label: 'Start Compatibility Quiz',
                  suffix: const Icon(Icons.arrow_forward, size: 18, color: AppColors.primary),
                  onTap: () => context.push(AppRoutes.roommateBudget),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text('Maybe later', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}