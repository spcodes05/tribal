import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/profile_setup_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../models/onboarding_profile_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/profile_flow_header.dart';
import '../../widgets/social_platform_card.dart';

/// Step 3 of 4 — Social Verification.
///
/// Lets the user mock-connect social accounts to boost their Trust Score,
/// per the proposal's "Social media linking, trust score computation"
/// requirement (Section 1.2). Connections are stubbed via
/// [ProfileSetupController.toggleSocialConnection] — ready to swap in real
/// OAuth flows later.
class SocialVerificationScreen extends StatelessWidget {
  const SocialVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProfileSetupController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileFlowHeader(
              currentStep: 3,
              totalSteps: 4,
              title: AppStrings.socialVerificationTitle,
              subtitle: AppStrings.socialVerificationSubtitle,
              onBack: () => context.pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform cards
                  ...SocialPlatform.values.map((platform) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SocialPlatformCard(
                        platform: platform,
                        isConnected: ctrl.isConnected(platform),
                        isConnecting: ctrl.connectingPlatform == platform,
                        onTap: () => ctrl.toggleSocialConnection(platform),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Benefits section
                  const _BenefitsSection(),

                  const SizedBox(height: 36),

                  // Next button
                  CustomButton(
                    label: AppStrings.nextLabel,
                    suffix: const Icon(Icons.arrow_forward, size: 18),
                    onTap: () => context.push(AppRoutes.profileSetup),
                  ),

                  const SizedBox(height: 16),

                  // Skip
                  Center(
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.profileSetup),
                      child: Text(
                        AppStrings.skipForNow,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Why connect?" benefits checklist shown below the platform cards.
class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.socialBenefitsTitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const _BenefitRow(text: AppStrings.socialBenefit1),
          const SizedBox(height: 8),
          const _BenefitRow(text: AppStrings.socialBenefit2),
          const SizedBox(height: 8),
          const _BenefitRow(text: AppStrings.socialBenefit3),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;
  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
