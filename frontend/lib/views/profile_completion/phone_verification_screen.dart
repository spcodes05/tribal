import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/profile_setup_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/profile_flow_header.dart';

/// Step 1 of 4 — Phone Verification.
///
/// Collects the user's phone number (defaulting to Nepal +977) to improve
/// their Trust Score, per the project proposal's "User & Trust Management"
/// module. Uses the shared [ProfileSetupController] provided higher up the
/// route tree so data persists across the rest of the flow.
class PhoneVerificationScreen extends StatelessWidget {
  const PhoneVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProfileSetupController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileFlowHeader(
              currentStep: 1,
              totalSteps: 4,
              title: AppStrings.phoneVerificationTitle,
              subtitle: AppStrings.phoneVerificationSubtitle,
              onBack: () => context.pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Phone illustration placeholder
                  const _PhoneIllustration(),

                  const SizedBox(height: 32),

                  // Phone number field with country code prefix
                  Form(
                    key: ctrl.phoneFormKey,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppStrings.phoneNumberLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  _PhoneInputRow(controller: ctrl),

                  const SizedBox(height: 14),

                  // Trust message
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.phoneTrustMessage,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Continue button
                  CustomButton(
                    label: AppStrings.continueLabel,
                    isLoading: ctrl.isVerifyingPhone,
                    onTap: ctrl.isPhoneValid
                        ? () async {
                      await ctrl.submitPhone();
                      if (context.mounted) {
                        context.push(AppRoutes.genderSelection);
                      }
                    }
                        : null,
                    suffix: const Icon(Icons.arrow_forward, size: 18),
                  ),

                  const SizedBox(height: 16),

                  // Skip for now
                  TextButton(
                    onPressed: () {
                      ctrl.skipPhone();
                      context.push(AppRoutes.genderSelection);
                    },
                    child: Text(
                      AppStrings.skipForNow,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
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

/// Large circular phone illustration placeholder.
/// Falls back gracefully — replace with a real illustration asset later.
class _PhoneIllustration extends StatelessWidget {
  const _PhoneIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.phone_iphone_rounded,
        size: 64,
        color: AppColors.primary,
      ),
    );
  }
}

/// Country code prefix + phone number input, styled to match
/// [CustomTextField] but with a non-editable country code segment.
class _PhoneInputRow extends StatelessWidget {
  final ProfileSetupController controller;

  const _PhoneInputRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Country code picker (defaults to Nepal, static for now)
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Text('🇳🇵', style: GoogleFonts.poppins(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                controller.profile.countryCode,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Phone number field
        Expanded(
          child: SizedBox(
            height: 52,
            child: TextFormField(
              controller: controller.phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              onChanged: controller.onPhoneChanged,
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                counterText: '',
                hintText: AppStrings.phoneNumberHint,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
